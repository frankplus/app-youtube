import  deviceInfo  from '@ohos.deviceInfo'
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KeyCode } from '@kit.InputKit';

// no User Agent, test
// https://tool.lu/useragent
// Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.88 Mobile Safari/537.36

// User Agent set in the offcial browser
// const PAD_USER_AGENT: string = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/92.0.4515.105 Safari/537.36'
// const PHONE_USER_AGENT: string = 'Mozilla/5.0 (Linux; Android 9; VRD-AL10; HMSCore 6.3.0.331) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/92.0.4515.105 HuaweiBrowser/12.0.4.1 Mobile Safari/537.36'

// User Agent modification from westinyang
const PAD_USER_AGENT: string = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/99.0.4844.88 Safari/537.36'
const PHONE_USER_AGENT: string = 'Mozilla/5.0 (Linux; Android 10.0; ohos) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/99.0.4844.88 HuaweiBrowser/13.0.4.302 Mobile Safari/537.36'

// Define the interface for the extended object
interface ExtObject {
  test: (str: string) => string;
}

@Entry
@Component
struct Index {
  // Implement the extended browser object
  extObj: ExtObject = {
    test: (str: string): string => {
      console.log("extObj.test: " + str);
      return "test " + str;
    }
  };
  controller: webview.WebviewController = new webview.WebviewController()

  aboutToAppear() {
    webview.WebviewController.initializeWebEngine();
    // Warm up the Service Worker for faster PWA start
    try {
      webview.WebviewController.warmupServiceWorker('https://2048.love2dev.com/');
    } catch (e) {
      console.warn(`Service Worker warmup failed: ${JSON.stringify(e)}`);
    }
  }

  build() {
    Column() {

      Row() {
        Text('PWA App')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .padding(12)
        Blank()
        Button('Reload')
          .onClick(() => this.controller.refresh())
          .margin({ right: 8 })
      }
      .backgroundColor('#b5b5b5ff')
      .width('100%')
    
      /* Load local web pages */
      // Web({ src: $rawfile("index.html"), controller: this.controller })

      /* Load online web pages */
      Web({ src: 'https://2048.love2dev.com/', controller: this.controller })
        .zoomAccess(false)
        .mediaPlayGestureAccess(true)
        .horizontalScrollBarAccess(false)
        .verticalScrollBarAccess(false)
        .fileAccess(true)
        .imageAccess(true)
        .onlineImageAccess(true)
        .domStorageAccess(true)
        .databaseAccess(true)
        .cacheMode(CacheMode.Default)
        .javaScriptAccess(true)
        .javaScriptProxy({
          object: this.extObj,
          name: "extObj",
          methodList: ["test"],
          controller: this.controller,
        })
        .onPageBegin((event) => {
          hilog.info(0x0, '[Index]', `onPageBegin= ${JSON.stringify(event)}`)
        })
        .onPageEnd((event) => {
          hilog.info(0x0, '[Index]', `onPageEnd= ${JSON.stringify(event)}`)
          // register browser object
          // this.controller.registerJavaScriptProxy(this.extObj, 'extObj', ['test'])
          // run js
          // this.controller.runJavaScript("jsMethodName(params)")
        })
        .onProgressChange((event) => {
          hilog.info(0x0, '[Index]', `onProgressChange`)
        })
        .width('100%')
        .height('100%')
        .backgroundColor('#ffffff')
    }
  }
}