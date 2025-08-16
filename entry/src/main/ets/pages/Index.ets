import  deviceInfo  from '@ohos.deviceInfo'
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
struct Index {
  // Implement the extended browser object
  extObj: ExtObject = {
    test: (str: string): string => {
      console.log("extObj.test: " + str);
      return "test " + str;
    }
  };
  controller: webview.WebviewController = new webview.WebviewController()
  @State currentUrl: string = '';
  @State showPWAView: boolean = false;
  @State currentPWAInfo: PWAInfo | null = null;
  
  private pwaManager = PWAManager.getInstance();

  aboutToAppear() {
    webview.WebviewController.initializeWebEngine();
    
    // Check if we're opening a specific PWA
    const params = router.getParams() as Record<string, string>;
    if (params && params.pwaUrl) {
      this.currentUrl = params.pwaUrl;
      this.showPWAView = true;
      this.loadPWAInfo(params.pwaUrl);
    } else {
      // Default behavior - navigate to PWA Store
      this.navigateToPWABrowser();
    }
  }
  
  async loadPWAInfo(url: string) {
    const context = getContext(this) as common.UIAbilityContext;
    const installedPWAs = await this.pwaManager.getInstalledPWAs(context);
    this.currentPWAInfo = installedPWAs.find(pwa => pwa.url === url) || null;
  }
  
  navigateToPWABrowser() {
    router.replaceUrl({
      url: 'pages/PWABrowser'
    });
  }
  
  navigateToInstalledPWAs() {
    router.pushUrl({
      url: 'pages/InstalledPWAs'
    });
  }

  build() {
    Column() {
      if (!this.showPWAView) {
        // Show navigation to PWA Store
        Column() {
          Image($r('app.media.app_icon'))
            .width(120)
            .height(120)
            .margin({ top: 80, bottom: 40 })
          
          Text('PWA Browser')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 16 })
          
          Text('Browse the web and discover Progressive Web Apps')
            .fontSize(16)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 40, left: 32, right: 32 })
          
          Button('Open PWA Browser')
            .onClick(() => this.navigateToPWABrowser())
            .backgroundColor('#007AFF')
            .fontColor(Color.White)
            .fontSize(18)
            .width(200)
            .height(50)
            .margin({ bottom: 20 })
          
          Button('My Installed PWAs')
            .onClick(() => this.navigateToInstalledPWAs())
            .backgroundColor('#34C759')
            .fontColor(Color.White)
            .fontSize(16)
            .width(200)
            .height(44)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .height('100%')
        .backgroundColor('#f8f8f8')
      } else {
        // Show PWA viewer
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
          .layoutWeight(1)
          .backgroundColor('#ffffff')
      }
    }
    .height('100%')
  }
}