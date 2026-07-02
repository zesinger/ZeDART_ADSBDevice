# ZeDART_ADSBDevice
Script pour créer le device ADS-B pour ZeDART

## MATERIEL
- Un Raspberry Pi 3 minimum et son alimentation
- Une carte micro SD de 8Go minimum (et une possibilité de la lire/écrire dans votre ordinateur, par exemple avec une clé USB lecteur de cartes micro SD)
- Un clé USB RTL-SDR compatible fréquence 1090MHz (ADS-B)
- Un câble Ethernet

## INSTALLATION
- Insérez la carte SD dans votre ordinateur
- Installez Raspberry Pi OS à l'aide de https://www.raspberrypi.com/software/ et lancez le:
  - Choisir "Raspberry Pi OS (other)" puis "Raspberry Pi OS Lite (64-bit)"
  - Choisir le lecteur associé à votre carte SD
  - Choisir un nom d'utilisateur
  - Choisir le fuseau horaire et le type de clavier
  - Retapez le nom d'utilisateur ainsi qu'un mot de passe
  - Rentrez les paramètres de votre connexion Wifi internet (juste de le temps de l'installation), le Wifi sera intuile après
  - Vous pouvez désactiver le SSH ainsi que Raspberry Pi Connect
  - Lancez l'écriture
- Une fois l'écriture terminée, insérez la carte micro SD dans votre Raspberry Pi, connectez-y également la clé RTL-SDR, un clavier et un écran, enfin reliez l'ordinateur au Raspberry Pi via la connexion Ethernet
- Alimentez votre Raspberry Pi et quand vous avez la main, tapez votre nom d'utilisateur puis votre mot de passe.
- Tapez `curl -fsSL https://raw.githubusercontent.com/zesinger/ZeDART_ADSBDevice/main/install-zedart.sh | sudo bash` en respectant les majuscules et les minuscules
- Patientez
- Vous pouvez déconnecter le clavier et l'écran, votre Raspberry Pi n'en a plus besoin, il suffit juste de le démarrer pour qu'il fonctionne
