import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { PWAManager, PWAInfo } from '../util/PWAManager';
import { common } from '@kit.AbilityKit';

// Define the interface for the extended object
interface ExtObject {
  test: (str: string) => string;
}

@Entry
@Component
struct PWAViewer {
  // Implement the extended browser object
  extObj: ExtObject = {
    test: (str: string): string => {
      console.log("extObj.test: " + str);
      return "test " + str;
    }
  };
  controller: webview.WebviewController = new webview.WebviewController()
  @State currentUrl: string = '';
  @State currentPWAInfo: PWAInfo | null = null;
  
  private pwaManager = PWAManager.getInstance();

  aboutToAppear() {
    webview.WebviewController.initializeWebEngine();
    
    // Get PWA URL from route parameters
    const params = router.getParams() as Record<string, string>;
    if (params && params.pwaUrl) {
      this.currentUrl = params.pwaUrl;
      this.loadPWAInfo(params.pwaUrl);
      
      // Warm up the Service Worker for faster PWA start
      try {
        webview.WebviewController.warmupServiceWorker(params.pwaUrl);
      } catch (e) {
        console.warn(`Service Worker warmup failed: ${JSON.stringify(e)}`);
      }
    }
  }
  
  async loadPWAInfo(url: string) {
    const context = getContext(this) as common.UIAbilityContext;
    const installedPWAs = await this.pwaManager.getInstalledPWAs(context);
    this.currentPWAInfo = installedPWAs.find(pwa => pwa.url === url) || null;
  }

  build() {
    Column() {
      // PWA Header
      Row() {
        Button('← Back')
          .onClick(() => router.back())
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .margin({ left: 8 })
        
        Column() {
          if (this.currentPWAInfo) {
            Text(this.currentPWAInfo.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          } else {
            Text('PWA App')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
        }
        .padding(12)
        .layoutWeight(1)
        
        Button('Reload')
          .onClick(() => this.controller.refresh())
          .margin({ right: 8 })
      }
      .backgroundColor('#f5f5f5')
      .width('100%')

      /* Load PWA URL */
      Web({ src: this.currentUrl, controller: this.controller })
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
          hilog.info(0x0, '[PWAViewer]', `onPageBegin= ${JSON.stringify(event)}`)
        })
        .onUrlLoadIntercept((event) => {
          hilog.info(0x0, '[PWAViewer]', `onUrlLoadIntercept= ${JSON.stringify(event)}`)
          
          if (event?.data && this.currentUrl) {
            let requestedUrl: string = '';
            
            // Handle both string and WebResourceRequest types
            if (typeof event.data === 'string') {
              requestedUrl = event.data;
            }
            
            // Check if the requested URL is outside the PWA domain
            if (requestedUrl && !this.pwaManager.isUrlInPWADomain(this.currentUrl, requestedUrl)) {
              hilog.info(0x0, '[PWAViewer]', `External URL detected: ${requestedUrl}, redirecting to PWABrowser`)
              
              // Navigate to PWABrowser with the external URL
              router.pushUrl({
                url: 'pages/PWABrowser',
                params: {
                  initialUrl: requestedUrl
                }
              });
              
              // Prevent the current webview from loading the external URL
              return true;
            }
          }
          
          // Allow normal navigation for URLs within the PWA domain
          return false;
        })
        .onPageEnd((event) => {
          hilog.info(0x0, '[PWAViewer]', `onPageEnd= ${JSON.stringify(event)}`)
          // register browser object
          // this.controller.registerJavaScriptProxy(this.extObj, 'extObj', ['test'])
          // run js
          // this.controller.runJavaScript("jsMethodName(params)")
        })
        .onProgressChange((event) => {
          hilog.info(0x0, '[PWAViewer]', `onProgressChange`)
        })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#ffffff')
    }
    .height('100%')
  }
}
