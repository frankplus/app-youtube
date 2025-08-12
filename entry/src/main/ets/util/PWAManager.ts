import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

export interface PWAInfo {
  name: string;
  url: string;
  icon?: string;
  description?: string;
  installDate: number;
}

export class PWAManager {
  private static instance: PWAManager;
  private preferencesKey = 'installed_pwas';
  
  private constructor() {}
  
  static getInstance(): PWAManager {
    if (!PWAManager.instance) {
      PWAManager.instance = new PWAManager();
    }
    return PWAManager.instance;
  }
  
  async getInstalledPWAs(context: Context): Promise<PWAInfo[]> {
    try {
      const prefs = await preferences.getPreferences(context, 'pwa_store');
      const installedPWAsStr = await prefs.get(this.preferencesKey, '[]') as string;
      return JSON.parse(installedPWAsStr);
    } catch (error) {
      console.error('Error getting installed PWAs:', error);
      return [];
    }
  }
  
  async installPWA(context: Context, pwaInfo: PWAInfo): Promise<boolean> {
    try {
      const installedPWAs = await this.getInstalledPWAs(context);
      
      // Check if PWA is already installed
      const existingIndex = installedPWAs.findIndex(pwa => pwa.url === pwaInfo.url);
      if (existingIndex !== -1) {
        return false; // Already installed
      }
      
      installedPWAs.push({
        ...pwaInfo,
        installDate: Date.now()
      });
      
      const prefs = await preferences.getPreferences(context, 'pwa_store');
      await prefs.put(this.preferencesKey, JSON.stringify(installedPWAs));
      await prefs.flush();
      
      return true;
    } catch (error) {
      console.error('Error installing PWA:', error);
      return false;
    }
  }
  
  async uninstallPWA(context: Context, url: string): Promise<boolean> {
    try {
      const installedPWAs = await this.getInstalledPWAs(context);
      const filteredPWAs = installedPWAs.filter(pwa => pwa.url !== url);
      
      const prefs = await preferences.getPreferences(context, 'pwa_store');
      await prefs.put(this.preferencesKey, JSON.stringify(filteredPWAs));
      await prefs.flush();
      
      return true;
    } catch (error) {
      console.error('Error uninstalling PWA:', error);
      return false;
    }
  }
  
  async isPWAInstalled(context: Context, url: string): Promise<boolean> {
    const installedPWAs = await this.getInstalledPWAs(context);
    return installedPWAs.some(pwa => pwa.url === url);
  }
}
