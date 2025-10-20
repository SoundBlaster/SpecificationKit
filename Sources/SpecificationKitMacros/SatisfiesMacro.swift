import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Diagnostic messages for the Satisfies macro
struct SatisfiesParameterTypeMismatchMessage: DiagnosticMessage {
    let parameterName: String
    let expectedType: String
    let actualType: String

    var message: String {
        "Parameter '\(parameterName)' expects type '\(expectedType)' but got '\(actualType)'"
    }

    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID {
        .init(domain: "SpecificationKitMacros", id: "satisfiesParameterTypeMismatch")
    }
}

struct SatisfiesSpecTypeNotFoundMessage: DiagnosticMessage {
    let typeName: String

    var message: String {
        "Specification type '\(typeName)' not found or does not conform to Specification protocol"
    }

    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID {
        .init(domain: "SpecificationKitMacros", id: "satisfiesSpecTypeNotFound")
    }
}

struct SatisfiesMissingRequiredParameterMessage: DiagnosticMessage {
    let parameterName: String
    let specType: String

    var message: String {
        "Required parameter '\(parameterName)' missing for specification type '\(specType)'"
    }

    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID {
        .init(domain: "SpecificationKitMacros", id: "satisfiesMissingRequiredParameter")
    }
}

/// Parameter information extracted from macro attributes
struct ParameterInfo {
    let name: String
    let value: ExprSyntax
    let type: String?

    init(name: String, value: ExprSyntax, type: String? = nil) {
        self.name = name
        self.value = value
        self.type = type
    }
}

/// Specification parameter metadata for type validation
struct SpecificationParameterMetadata {
    let parameterName: String
    let parameterType: String
    let isRequired: Bool
    let defaultValue: String?

    init(name: String, type: String, required: Bool = true, defaultValue: String? = nil) {
        self.parameterName = name
        self.parameterType = type
        self.isRequired = required
        self.defaultValue = defaultValue
    }
}

/// Parser for extracting parameters from macro attribute syntax
struct SpecificationParameterParser {

    /// Extract parameters from the macro attribute arguments
    func extractParameters(from arguments: LabeledExprListSyntax) -> (
        specType: String?, parameters: [ParameterInfo]
    ) {
        var specType: String?
        var parameters: [ParameterInfo] = []

        for argument in arguments {
            if let label = argument.label?.text {
                // Named parameter
                if label == "using" {
                    // Extract spec type from .self expression
                    if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
                        memberAccess.declName.baseName.text == "self"
                    {
                        specType = memberAccess.base?.trimmedDescription
                    }
                } else {
                    // Constructor parameter
                    parameters.append(ParameterInfo(name: label, value: argument.expression))
                }
            } else {
                // Handle unlabeled using parameter
                if specType == nil,
                    let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
                    memberAccess.declName.baseName.text == "self"
                {
                    specType = memberAccess.base?.trimmedDescription
                }
            }
        }

        return (specType: specType, parameters: parameters)
    }

    /// Get parameter metadata for known specification types
    func getParameterMetadata(for specType: String) -> [SpecificationParameterMetadata]? {
        switch specType {
        case "CooldownIntervalSpec":
            return [
                SpecificationParameterMetadata(name: "eventKey", type: "String"),
                SpecificationParameterMetadata(name: "cooldownInterval", type: "TimeInterval"),
            ]
        case "MaxCountSpec":
            return [
                SpecificationParameterMetadata(name: "counterKey", type: "String"),
                SpecificationParameterMetadata(name: "maxCount", type: "Int"),
            ]
        case "TimeSinceEventSpec":
            return [
                SpecificationParameterMetadata(name: "eventKey", type: "String"),
                SpecificationParameterMetadata(name: "minimumInterval", type: "TimeInterval"),
            ]
        case "FeatureFlagSpec":
            return [
                SpecificationParameterMetadata(name: "flagKey", type: "String"),
                SpecificationParameterMetadata(
                    name: "expectedValue", type: "Bool", required: false, defaultValue: "true"),
            ]
        case "DateRangeSpec":
            return [
                SpecificationParameterMetadata(name: "startDate", type: "Date"),
                SpecificationParameterMetadata(name: "endDate", type: "Date"),
            ]
        case "DateComparisonSpec":
            return [
                SpecificationParameterMetadata(name: "targetDate", type: "Date"),
                SpecificationParameterMetadata(
                    name: "comparison", type: "DateComparisonSpec.Comparison"),
            ]
        case "PredicateSpec":
            return [
                SpecificationParameterMetadata(name: "predicate", type: "(T) -> Bool")
            ]
        default:
            return nil
        }
    }

    /// Validate parameter types against specification requirements
    func validateParameterTypes(
        specType: String,
        parameters: [ParameterInfo],
        context: some MacroExpansionContext
    ) -> [Diagnostic] {
        guard let expectedParameters = getParameterMetadata(for: specType) else {
            return [
                Diagnostic(
                    node: Syntax(StringLiteralExprSyntax(content: specType)),
                    message: SatisfiesSpecTypeNotFoundMessage(typeName: specType))
            ]
        }

        var diagnostics: [Diagnostic] = []
        let providedParameterNames = Set(parameters.map { $0.name })

        // Check for missing required parameters
        for expectedParam in expectedParameters {
            if expectedParam.isRequired
                && !providedParameterNames.contains(expectedParam.parameterName)
            {
                diagnostics.append(
                    Diagnostic(
                        node: Syntax(StringLiteralExprSyntax(content: expectedParam.parameterName)),
                        message: SatisfiesMissingRequiredParameterMessage(
                            parameterName: expectedParam.parameterName,
                            specType: specType
                        )
                    )
                )
            }
        }

        // Check parameter type compatibility (basic validation)
        let expectedParameterMap = Dictionary(
            uniqueKeysWithValues: expectedParameters.map { ($0.parameterName, $0) })

        for parameter in parameters {
            if let expectedParam = expectedParameterMap[parameter.name] {
                let inferredType = inferParameterType(from: parameter.value)
                if !isTypeCompatible(
                    inferredType: inferredType, expectedType: expectedParam.parameterType)
                {
                    diagnostics.append(
                        Diagnostic(
                            node: Syntax(parameter.value),
                            message: SatisfiesParameterTypeMismatchMessage(
                                parameterName: parameter.name,
                                expectedType: expectedParam.parameterType,
                                actualType: inferredType
                            )
                        )
                    )
                }
            }
        }

        return diagnostics
    }

    /// Infer the type of a parameter expression (basic implementation)
    private func inferParameterType(from expression: ExprSyntax) -> String {
        if expression.is(StringLiteralExprSyntax.self) {
            return "String"
        } else if expression.is(IntegerLiteralExprSyntax.self) {
            return "Int"
        } else if expression.is(FloatLiteralExprSyntax.self) {
            return "Double"
        } else if expression.is(BooleanLiteralExprSyntax.self) {
            return "Bool"
        } else {
            return "Unknown"
        }
    }

    /// Check if inferred type is compatible with expected type (basic implementation)
    private func isTypeCompatible(inferredType: String, expectedType: String) -> Bool {
        // Basic type compatibility checks
        switch (inferredType, expectedType) {
        case ("String", "String"):
            return true
        case ("Int", "Int"), ("Int", "TimeInterval"), ("Double", "TimeInterval"):
            return true
        case ("Double", "Double"), ("Double", "TimeInterval"):
            return true
        case ("Bool", "Bool"):
            return true
        case ("Unknown", _):
            return true  // Skip validation for complex expressions
        default:
            return false
        }
    }
}

/// Errors that can be thrown by the SatisfiesMacro
public enum SatisfiesMacroError: CustomStringConvertible, Error {
    case requiresArguments
    case requiresSpecificationType
    case parameterValidationFailed

    public var description: String {
        switch self {
        case .requiresArguments:
            return
                "SatisfiesSpec macro requires at least one argument specifying the specification type"
        case .requiresSpecificationType:
            return
                "SatisfiesSpec macro requires a specification type (e.g., CooldownIntervalSpec.self)"
        case .parameterValidationFailed:
            return "SatisfiesSpec macro parameter validation failed"
        }
    }
}

/// Macro for creating @Satisfies property wrappers with parameter support
/// This is a freestanding macro that expands to the full property wrapper syntax
/// Usage: #SatisfiesSpec(using: CooldownIntervalSpec.self, eventKey: "action", cooldownInterval: 10)
public struct SatisfiesMacro: ExpressionMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        let arguments = node.arguments
        guard !arguments.isEmpty else {
            throw SatisfiesMacroError.requiresArguments
        }

        let parser = SpecificationParameterParser()
        let (specType, parameters) = parser.extractParameters(from: arguments)

        guard let specType = specType else {
            throw SatisfiesMacroError.requiresSpecificationType
        }

        // Validate parameters
        let diagnostics = parser.validateParameterTypes(
            specType: specType,
            parameters: parameters,
            context: context
        )

        // Report any validation errors
        for diagnostic in diagnostics {
            context.diagnose(diagnostic)
        }

        if !diagnostics.isEmpty {
            throw SatisfiesMacroError.parameterValidationFailed
        }

        // Generate the specification instantiation code
        let parameterList = parameters.map { param in
            "\(param.name): \(param.value.trimmedDescription)"
        }.joined(separator: ", ")

        let specInstanceCode = "\(specType)(\(parameterList))"

        // Return the expression that creates a Satisfies property wrapper
        return "Satisfies(using: \(raw: specInstanceCode))"
    }
}
