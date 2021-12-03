# waifuExtension
The waifu2x on Mac.

Use this app to enlarge your images, videos with Machine Learning. It also supports frames Interpolation.

The new version is capable of taking advantages of CPU, GPU, and [ANE](https://github.com/hollance/neural-engine).

## Usage
Enlarge videos or images with machine learning on Mac.

## Install
Files and source code could be found in [releases](https://github.com/Vaida12345/waifuExtension/releases).

## Privacy
This app works completely offline and requires no internet connection. Nothing is collected or stored, expect for some temp files stored in the [container](https://developer.apple.com/documentation/foundation/1413045-nshomedirectory/) of the app. These files will be deleted when the app is opened.

## Models
The models where obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe), and translated to coreML via [coremltools](https://github.com/apple/coremltools).

## Note
This app was based on the work of [waifu2x-ios](https://github.com/imxieyi/waifu2x-ios). Nearly all the files in the folder "waifu2x-mac" were created by him. However, modifications were done to improve speed.

## Speed
When processing a standard 1080p image (1920 × 1080), MacBook Pro with the M1 Max chip took only 0.7 seconds.

## Interface
This app was written with [SwiftUI](https://developer.apple.com/xcode/swiftui/).
<img width="1720" alt="Screen Shot 2021-11-29 at 2 20 33 PM" src="https://user-images.githubusercontent.com/91354917/143818805-dffb73c7-835c-4b06-9227-a531c90b6364.png">

## Preview
<img width="1417" alt="Screen Shot 2021-11-29 at 2 44 41 PM" src="https://user-images.githubusercontent.com/91354917/143820789-45edbf68-a0c5-4478-be80-b26da1a3ce9c.png">

## Denoise Level
You can compare results from different model by choosing Compare > Compare Models. Example:
<img width="1446" alt="Screen Shot 2021-11-29 at 5 58 27 PM" src="https://user-images.githubusercontent.com/91354917/143847147-b6b12fee-9761-4dab-8899-fa49ea02c63f.png">

## Credits
 - [waifu2x-ios](https://github.com/imxieyi/waifu2x-ios) for nearly all the algorithms used to enlarge images.
 - [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe) for all the models.
 - [stack overflow](https://stackoverflow.com) for all the solutions.
 - [dain-ncnn-vulkan](https://github.com/nihui/dain-ncnn-vulkan) for frame implemented AI.
