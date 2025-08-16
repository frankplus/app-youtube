import  deviceInfo  from '@ohos.deviceInfo'
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { PWAManager, PWAInfo } from '../util/PWAManager';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State currentUrl: string = '';
  @State currentPWAInfo: PWAInfo | null = null;
  
  private pwaManager = PWAManager.getInstance();

  aboutToAppear() {
    webview.WebviewController.initializeWebEngine();
    
    // Check if we're opening a specific PWA
    const params = router.getParams() as Record<string, string>;
    if (params && params.pwaUrl) {
      // If a PWA URL is provided, navigate to PWAViewer
      router.replaceUrl({
        url: 'pages/PWAViewer',
        params: {
          pwaUrl: params.pwaUrl
        }
      });
    } else {
      // Default behavior - navigate to PWA Browser
      this.navigateToPWABrowser();
    }
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
    }
    .height('100%')
  }
}