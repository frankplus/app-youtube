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
struct PWABrowser {
  controller: webview.WebviewController = new webview.WebviewController();
  @State showInstallButton: boolean = false;
  @State currentPWAInfo: PWAInfo | null = null;
  @State isLoading: boolean = false;
  @State currentUrl: string = 'https://www.findpwa.com/';
  @State urlInput: string = 'https://www.findpwa.com/';
  @State showingPWA: boolean = false;
  @State installedPWAs: PWAInfo[] = [];
  @State isLoadingPWAs: boolean = true;
  
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
    this.loadInstalledPWAs();
    
    // Check if we're opening a specific PWA
    const params = router.getParams() as Record<string, string>;
    if (params && params.pwaUrl) {
      this.openPWADirectly(params.pwaUrl);
    }
  }
  
  async loadInstalledPWAs() {
    this.isLoadingPWAs = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.installedPWAs = await this.pwaManager.getInstalledPWAs(context);
    } catch (error) {
      console.error('Error loading installed PWAs:', error);
    }
    this.isLoadingPWAs = false;
  }
  
  openPWADirectly(url: string) {
    this.currentUrl = url;
    this.urlInput = url;
    this.showingPWA = true;
    // Don't call controller.loadUrl here - let the Web component handle the URL change
  }
  
  navigateToUrl() {
    let url = this.urlInput.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }
    this.currentUrl = url;
    this.showingPWA = true;
    // Don't call controller.loadUrl here - let the Web component handle the URL change
  }
  
  returnToMainPage() {
    this.showingPWA = false;
    this.showInstallButton = false;
    this.currentPWAInfo = null;
    this.loadInstalledPWAs(); // Refresh installed PWAs list
  }
  
  async uninstallPWA(url: string, name: string) {
    const context = getContext(this) as common.UIAbilityContext;
    const success = await this.pwaManager.uninstallPWA(context, url);
    if (success) {
      await this.loadInstalledPWAs(); // Refresh the list
    }
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
        await this.loadInstalledPWAs(); // Refresh installed PWAs list
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
      if (!this.showingPWA) {
        // Main browser page with URL bar and installed PWAs
        Column() {
          // Header
          Row() {
            Text('PWA Browser')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .padding(12)
            
            Blank()
          }
          .backgroundColor('#f5f5f5')
          .width('100%')
          
          // URL bar
          Row() {
            TextInput({
              placeholder: 'Enter URL or search...',
              text: this.urlInput
            })
              .onChange((value: string) => {
                this.urlInput = value;
              })
              .onSubmit(() => {
                this.navigateToUrl();
              })
              .layoutWeight(1)
              .margin({ right: 8 })
            
            Button('Go')
              .onClick(() => this.navigateToUrl())
              .backgroundColor('#007AFF')
              .fontColor(Color.White)
          }
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#ffffff')
          .width('100%')
          
          // Installed PWAs section
          Column() {
            Row() {
              Text('Installed PWAs')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .padding({ left: 12, top: 12, bottom: 8 })
              
              Blank()
              
              if (this.installedPWAs.length > 0) {
                Button('View All')
                  .onClick(() => this.navigateToInstalledPWAs())
                  .backgroundColor('#34C759')
                  .fontColor(Color.White)
                  .fontSize(12)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .margin({ right: 12 })
              }
            }
            .width('100%')
            
            if (this.isLoadingPWAs) {
              Row() {
                LoadingProgress()
                  .width(30)
                  .height(30)
                Text('Loading PWAs...')
                  .fontSize(14)
                  .margin({ left: 12 })
              }
              .padding(16)
              .justifyContent(FlexAlign.Center)
            } else if (this.installedPWAs.length === 0) {
              Column() {
                Text('No PWAs installed yet')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 8 })
                
                Text('Browse the web and install PWAs to see them here')
                  .fontSize(12)
                  .fontColor('#888888')
                  .textAlign(TextAlign.Center)
              }
              .padding(16)
              .alignItems(HorizontalAlign.Center)
            } else {
              // PWA grid
              Grid() {
                ForEach(this.installedPWAs.slice(0, 6), (pwa: PWAInfo, index: number) => {
                  GridItem() {
                    Column() {
                      // PWA Icon
                      if (pwa.icon) {
                        Image(pwa.icon)
                          .width(40)
                          .height(40)
                          .borderRadius(8)
                          .margin({ bottom: 4 })
                      } else {
                        Row() {
                          Text(pwa.name.charAt(0).toUpperCase())
                            .fontSize(16)
                            .fontColor(Color.White)
                        }
                        .width(40)
                        .height(40)
                        .backgroundColor('#007AFF')
                        .borderRadius(8)
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)
                        .margin({ bottom: 4 })
                      }
                      
                      Text(pwa.name)
                        .fontSize(10)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .textAlign(TextAlign.Center)
                        .height(24)
                    }
                    .width('100%')
                    .padding(8)
                    .backgroundColor(Color.White)
                    .borderRadius(8)
                    .shadow({
                      radius: 2,
                      color: '#0000001A',
                      offsetX: 0,
                      offsetY: 1
                    })
                    .onClick(() => {
                      this.openPWADirectly(pwa.url);
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr 1fr')
              .rowsGap(8)
              .columnsGap(8)
              .padding({ left: 12, right: 12, bottom: 12 })
            }
          }
          .backgroundColor('#f8f8f8')
          .width('100%')
          .layoutWeight(1)
        }
        .height('100%')
      } else {
        // PWA viewing mode
        Column() {
          // Header for PWA mode
          Row() {
            Button('← Back')
              .onClick(() => this.returnToMainPage())
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
                Text('Web App')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .padding(12)
            .layoutWeight(1)
            
            // Install PWA button
            if (this.showInstallButton && this.currentPWAInfo) {
              Button(this.isLoading ? 'Installing...' : 'Install')
                .onClick(() => this.installCurrentPWA())
                .enabled(!this.isLoading)
                .backgroundColor('#34C759')
                .fontColor(Color.White)
                .fontSize(12)
                .margin({ right: 8 })
            }
            
            Button('Reload')
              .onClick(() => this.controller.refresh())
              .fontSize(12)
              .margin({ right: 8 })
          }
          .backgroundColor('#f5f5f5')
          .width('100%')
          
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
          
          // Web view
          Web({ 
            src: this.currentUrl, 
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
              hilog.info(0x0, '[PWABrowser]', `onPageEnd= ${JSON.stringify(event)}`);
              
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
    .height('100%')
  }
}
