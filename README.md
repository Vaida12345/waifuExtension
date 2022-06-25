# waifuExtension
The waifu2x on Mac.

## Usage
- Enlarge videos or images with machine learning on Mac.
- Interpolate frames for videos.

## Install
Files and source code could be found in [releases](https://github.com/Vaida12345/waifuExtension/releases).

Note: If mac says the app was damaged / unknown developer, please go to `System Preferences > Security & Privacy > General`, and click `Open Anyway`. [Show Details.](https://github.com/Vaida12345/Annotation/wiki#why-i-cant-open-the-app)

## Privacy
This app works completely offline and requires no internet connection. Nothing is collected or stored, expect for:
- Your settings stored in its [containter](https://developer.apple.com/documentation/foundation/1413045-nshomedirectory/).
- Temp images in during comparison. (These files will be deleted when the windows is closed.)
- Temp images during processing in its container, the existance would only last for three lines of code, after which it is deleted.
- Output files and logs (if you turn on "enable log" or "enable dev" in preference) in its output path.

If the app crashes, please choose not to share crash log with Apple.

## Models
The models where obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe), and translated to coreML via [coremltools](https://github.com/apple/coremltools).

Other models are:
 - [dain-ncnn-vulkan](https://github.com/nihui/dain-ncnn-vulkan)
 - [realsr-ncnn-vulkan](https://github.com/nihui/realsr-ncnn-vulkan)
 - [cain-ncnn-vulkan](https://github.com/nihui/cain-ncnn-vulkan)
 - [realcugan-ncnn-vulkan](https://github.com/nihui/realcugan-ncnn-vulkan)
 - [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN)
 - [rife-ncnn-vulkan](https://github.com/nihui/rife-ncnn-vulkan)

## Note
The waifu2x model of this app was based on the work of [waifu2x-ios](https://github.com/imxieyi/waifu2x-ios). Nearly all the files in the folder "waifu2x-mac" were created by him. Nevertheless, modifications were done to improve speed.

The other models are simply executable file releases from their authors.

## Speed
When processing a standard 1080p image (1920 × 1080) using Waifu2x, MacBook Pro with the M1 Max chip took only 0.7 seconds.

## Interface
This app was written with [SwiftUI](https://developer.apple.com/xcode/swiftui/).

<img width="2000" alt="Interface" src="https://user-images.githubusercontent.com/91354917/158416387-74fb8c62-f38a-4814-b992-6706d4747948.png">


## Preview
<img width="1417" alt="Screen Shot 2021-11-29 at 2 44 41 PM" src="https://user-images.githubusercontent.com/91354917/143820789-45edbf68-a0c5-4478-be80-b26da1a3ce9c.png">

<img width="1013" alt="Screen Shot 2022-02-22 at 6 15 29 PM" src="https://user-images.githubusercontent.com/91354917/155111707-9ceff33a-d786-40a6-be7e-836f9475074f.png">


## Denoise Level
You can compare results from different model by choosing Compare > Compare Denoise Levels. Example:
<img width="1446" alt="Screen Shot 2021-11-29 at 5 58 27 PM" src="https://user-images.githubusercontent.com/91354917/143847147-b6b12fee-9761-4dab-8899-fa49ea02c63f.png">


## Credits
 - [waifu2x-ios](https://github.com/imxieyi/waifu2x-ios) for nearly all the algorithms used to enlarge images.
 - [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe) for all the models.
 - [stack overflow](https://stackoverflow.com) for all the solutions.
 - [dain-ncnn-vulkan](https://github.com/nihui/dain-ncnn-vulkan) for dain-ncnn-vulkan.
 - [realsr-ncnn-vulkan](https://github.com/nihui/realsr-ncnn-vulkan) for realsr-ncnn-vulkan.
 - [cain-ncnn-vulkan](https://github.com/nihui/cain-ncnn-vulkan) for cain-ncnn-vulkan.
 - [realcugan-ncnn-vulkan](https://github.com/nihui/realcugan-ncnn-vulkan) for realcugan-ncnn-vulkan.
 - [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) for Real-ESRGAN.
 - [rife-ncnn-vulkan](https://github.com/nihui/rife-ncnn-vulkan) for rife-ncnn-vulkan.
