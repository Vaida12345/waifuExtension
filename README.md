# waifuExtension
The waifu2x on Mac.

The new version is capable of taking advantages of CPU, GPU, and ANE.

## Usage
Enlarge videos or images with machine learning on Mac.

## Install
Files and source code could be found in [releases](https://github.com/Vaida12345/waifuExtension/releases/tag/v2.4.2).

## Models
The models where obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe), and translated to coreML via [coremltools](https://github.com/apple/coremltools).

## Note
This project was based on the work of [waifu2x-ios](https://github.com/imxieyi/waifu2x-ios). Nearly all the files in waifu2x-mac were created by him. However, I modified a few things to make it run much faster.

## Speed
When processing a stanard 1080p image (1920 x 1080), my Macbook Pro with the M1Max chip took only 0.7 seconds. Please note that it may be slow to run on intel-based Macs, as Macs with Apple silicon can accelerate machine learning results with ANE, aka, Apple Neural Engine.

## UI
This app was written with [SwiftUI](https://developer.apple.com/xcode/swiftui/).
<img width="1720" alt="Screen Shot 2021-11-29 at 2 20 33 PM" src="https://user-images.githubusercontent.com/91354917/143818805-dffb73c7-835c-4b06-9227-a531c90b6364.png">
