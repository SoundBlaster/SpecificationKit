## Steps
Defines a set of tasks the reader performs on a tutorial page.
Swift-DocC 5.5+
@Steps {
    ...
}
Overview
Use the Steps directive to define a set of tasks the reader performs on a tutorial page.
A screenshot showing three steps on a tutorial page.
Each individual step contains instructional text along with either a code listing, an image , or a video.
@Tutorial(time: 30) {

    ...

    @Section(title: "Create a Swift Package") {
        @ContentAndMedia {


            ...


        }

        @Steps {
            @Step {
                Create a new directory named `SwiftPackage`.

                @Code(name: "CreateDirectory.sh", file: 01-create-dir.sh) {
                    @Image(source: preview-01-create-directory.png, alt: "A screenshot from the command-line showing creating the directory using the `mkdir SwiftPackage` command.")
                }
            }


        @Step {
            Change into the new directory.

            @Code(name: "ChangeDirectory.sh", file: 02-change-directory.sh) {
                @Image(source: preview-02-change-directory.png, alt: "A screenshot from the command-line showing changing into the directory using the `cd SwiftPackage` command.")
            }
        }


            @Step {
                Create a new Swift Package.

                @Code(name: "Package.swift", file: 03-create-package.sh) {
                    @Image(source: preview-03-create-package.png, alt: "A screenshot from the command-line showing Swift Package creation using the `swift package init` command.")
                }
            }

            ...


        }
    }
}
Contained Elements
A set of steps can contain one or more of the following items:
Step
An individual task the reader performs. (optional)
Containing Elements
The following items can include a set of steps:
Section
Topics
Adding Individual Steps
@Step
Defines an individual task the reader performs within a set of steps on a tutorial page.

## Step
Defines an individual task the reader performs within a set of steps on a tutorial page.
Swift-DocC 5.5+
@Step {
    ...
}
Overview
Use the Step directive to define a single task the reader performs within a set of steps on a tutorial page. Provide text that explains what to do, and provide a code listing , an image, or a video that illustrates the step.
A screenshot showing a step on a tutorial page. The step has instructional text and a corresponding image.
@Tutorial(time: 30) {
    @Intro(title: "Creating Custom Sloths") {

        ...


    }

    @Section(title: "Create a new folder and add SlothCreator") {
        @ContentAndMedia {

            ...

        }

        @Steps {
            @Step {
                Create the folder.

                @Image(source: placeholder-image, alt: "A screenshot using the `mkdir` command to create a folder to place SlothCreator in.")
            }

            ...

        }
    }
}
Tip
Don’t number steps. Steps are automatically numbered in the rendered documentation.
Setting Context for a Step
To provide additional context about the step, add text before or after the step.
A screenshot showing a step on a tutorial page. The step is preceded with context-setting text.
The following steps display your customized sloth view in the preview.


@Step {
    Add the `sloth` parameter to initialize the `CustomizedSlothView` in the preview provider, and pass a new `Sloth` instance for the value.

    @Code(name: "CustomizedSlothView.swift", file: 01-creating-code-02-07.swift) {
        @Image(source: preview-01-creating-code-02-07.png, alt: "A portrait of a generic sloth displayed in the center of the canvas.")
    }
}
Contained Elements
A step contains one the following items:
Code
A code listing, and optionally a preview of the expected result, reader sees when they reach the step. (optional)
Image
An image the reader sees when they reach the step. (optional)
Video
A video the reader sees when they reach the step. (optional)
Containing Elements
The following items can include a step:
Steps
Topics
Displaying Code
@Code(...)
Defines the code for an individual step on a tutorial page.
Displaying Media
@Image(source: ResourceReference, alt: String)
Displays an image in a tutorial.
@Video(source: ResourceReference, alt: String, poster: ResourceReference)
Displays a video in a tutorial.
