import { router } from '@kit.ArkUI';
import { PWAManager, PWAInfo } from '../util/PWAManager';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct InstalledPWAs {
  @State installedPWAs: PWAInfo[] = [];
  @State isLoading: boolean = true;
  
  private pwaManager = PWAManager.getInstance();
  
  async aboutToAppear() {
    await this.loadInstalledPWAs();
  }
  
  async loadInstalledPWAs() {
    this.isLoading = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.installedPWAs = await this.pwaManager.getInstalledPWAs(context);
    } catch (error) {
      console.error('Error loading installed PWAs:', error);
    }
    this.isLoading = false;
  }
  
  async uninstallPWA(url: string, name: string) {
    const context = getContext(this) as common.UIAbilityContext;
    const success = await this.pwaManager.uninstallPWA(context, url);
    if (success) {
      await this.loadInstalledPWAs(); // Refresh the list
    }
  }
  
  openPWA(url: string) {
    router.pushUrl({
      url: 'pages/PWAViewer',
      params: {
        pwaUrl: url
      }
    });
  }
  
  navigateToStore() {
    router.back();
  }
  
  build() {
    Column() {
      // Header
      Row() {
        Button('← Back to Browser')
          .onClick(() => this.navigateToStore())
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .margin({ left: 8 })
        
        Blank()
        
        Text('My PWAs')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .padding(12)
        
        Blank()
        
        Button('Refresh')
          .onClick(() => this.loadInstalledPWAs())
          .margin({ right: 8 })
      }
      .backgroundColor('#f5f5f5')
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(60)
            .height(60)
          Text('Loading PWAs...')
            .fontSize(16)
            .margin({ top: 16 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      } else if (this.installedPWAs.length === 0) {
        Column() {
          Image($r('app.media.app_icon'))
            .width(80)
            .height(80)
            .opacity(0.5)
          
          Text('No PWAs Installed')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 16 })
          
          Text('Visit the PWA Browser to discover and install Progressive Web Apps')
            .fontSize(14)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .margin({ top: 8, left: 24, right: 24 })
          
          Button('Go to Browser')
            .onClick(() => this.navigateToStore())
            .backgroundColor('#007AFF')
            .fontColor(Color.White)
            .margin({ top: 24 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      } else {
        // PWA List
        List({ space: 8 }) {
          ForEach(this.installedPWAs, (pwa: PWAInfo) => {
            ListItem() {
              Row() {
                // PWA Icon
                if (pwa.icon) {
                  Image(pwa.icon)
                    .width(50)
                    .height(50)
                    .borderRadius(8)
                    .margin({ right: 12 })
                } else {
                  Row() {
                    Text(pwa.name.charAt(0).toUpperCase())
                      .fontSize(20)
                      .fontColor(Color.White)
                  }
                  .width(50)
                  .height(50)
                  .backgroundColor('#007AFF')
                  .borderRadius(8)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .margin({ right: 12 })
                }
                
                // PWA Info
                Column() {
                  Text(pwa.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  
                  Text(pwa.url)
                    .fontSize(12)
                    .fontColor('#666666')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
                  
                  if (pwa.description) {
                    Text(pwa.description)
                      .fontSize(12)
                      .fontColor('#888888')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 4 })
                  }
                  
                  Text(`Installed: ${new Date(pwa.installDate).toLocaleDateString()}`)
                    .fontSize(10)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                
                // Action buttons
                Column() {
                  Button('Open')
                    .onClick(() => this.openPWA(pwa.url))
                    .backgroundColor('#34C759')
                    .fontColor(Color.White)
                    .fontSize(12)
                    .width(90)
                    .height(32)
                  
                  Button('Remove')
                    .onClick(() => this.uninstallPWA(pwa.url, pwa.name))
                    .backgroundColor('#FF3B30')
                    .fontColor(Color.White)
                    .fontSize(12)
                    .width(90)
                    .height(32)
                    .margin({ top: 8 })
                }
                .margin({ left: 12 })
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .shadow({
                radius: 4,
                color: '#0000001A',
                offsetX: 0,
                offsetY: 2
              })
            }
          })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
    }
  }
}
