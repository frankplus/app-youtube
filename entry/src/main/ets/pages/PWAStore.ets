import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { PWAManager, PWAInfo } from '../util/PWAManager';
import { common } from '@kit.AbilityKit';

interface ExtendedObject {
  onPWADetected: (pwaInfoStr: string) => void;
}

@Entry
@Component
struct PWAStore {
  controller: webview.WebviewController = new webview.WebviewController();
  @State showInstallButton: boolean = false;
  @State currentPWAInfo: PWAInfo | null = null;
  @State isLoading: boolean = false;
  
  private pwaManager = PWAManager.getInstance();
  
  // PWA detection script to inject into the page
  private pwaDetectionScript = `
    (function() {
      function detectPWA() {
        const manifest = document.querySelector('link[rel="manifest"]');
        const serviceWorker = 'serviceWorker' in navigator;
        
        if (manifest && serviceWorker) {
          fetch(manifest.href)
            .then(response => response.json())
            .then(manifestData => {
              const pwaInfo = {
                name: manifestData.name || manifestData.short_name || document.title,
                url: window.location.href,
                icon: manifestData.icons && manifestData.icons.length > 0 ? 
                      new URL(manifestData.icons[0].src, window.location.href).href : null,
                description: manifestData.description || ''
              };
              
              window.extObj.onPWADetected(JSON.stringify(pwaInfo));
            })
            .catch(error => {
              console.log('Error fetching manifest:', error);
            });
        }
      }
      
      // Run detection after page load
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', detectPWA);
      } else {
        detectPWA();
      }
    })();
  `;
  
  aboutToAppear() {
    webview.WebviewController.initializeWebEngine();
  }
  
  // Extended object for PWA detection
  extObj: ExtendedObject = {
    onPWADetected: (pwaInfoStr: string) => {
      try {
        const pwaInfo: PWAInfo = JSON.parse(pwaInfoStr);
        this.currentPWAInfo = pwaInfo;
        
        // Check if already installed
        const context = getContext(this) as common.UIAbilityContext;
        this.pwaManager.isPWAInstalled(context, pwaInfo.url).then(isInstalled => {
          this.showInstallButton = !isInstalled;
        });
      } catch (error) {
        console.error('Error parsing PWA info:', error);
      }
    }
  };
  
  async installCurrentPWA() {
    if (this.currentPWAInfo) {
      this.isLoading = true;
      const context = getContext(this) as common.UIAbilityContext;
      const success = await this.pwaManager.installPWA(context, this.currentPWAInfo);
      this.isLoading = false;
      
      if (success) {
        this.showInstallButton = false;
        // Show success message or animation
      }
    }
  }
  
  navigateToInstalledPWAs() {
    router.pushUrl({
      url: 'pages/InstalledPWAs'
    });
  }
  
  build() {
    Column() {
      // Header with navigation
      Row() {
        Text('PWA Store')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .padding(12)
        
        Blank()
        
        // Install PWA button
        if (this.showInstallButton && this.currentPWAInfo) {
          Button(this.isLoading ? 'Installing...' : 'Install PWA')
            .onClick(() => this.installCurrentPWA())
            .enabled(!this.isLoading)
            .backgroundColor('#007AFF')
            .fontColor(Color.White)
            .margin({ right: 8 })
        }
        
        Button('My PWAs')
          .onClick(() => this.navigateToInstalledPWAs())
          .backgroundColor('#34C759')
          .fontColor(Color.White)
          .margin({ right: 8 })
        
        Button('Reload')
          .onClick(() => this.controller.refresh())
          .margin({ right: 8 })
      }
      .backgroundColor('#f5f5f5')
      .width('100%')
      .padding({ left: 8, right: 8 })
      
      // PWA install notification
      if (this.showInstallButton && this.currentPWAInfo) {
        Row() {
          Text(`PWA detected: ${this.currentPWAInfo.name}`)
            .fontSize(14)
            .fontColor('#007AFF')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        }
        .backgroundColor('#E3F2FD')
        .width('100%')
      }
      
      // Web view showing findpwa.com
      Web({ 
        src: 'https://www.findpwa.com/', 
        controller: this.controller 
      })
        .zoomAccess(true)
        .mediaPlayGestureAccess(true)
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
          methodList: ["onPWADetected"],
          controller: this.controller,
        })
        .onPageEnd((event) => {
          hilog.info(0x0, '[PWAStore]', `onPageEnd= ${JSON.stringify(event)}`);
          
          // Inject PWA detection script
          this.controller.runJavaScript(this.pwaDetectionScript)
            .then(() => {
              console.log('PWA detection script injected successfully');
            });
        })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#ffffff')
    }
    .height('100%')
  }
}
