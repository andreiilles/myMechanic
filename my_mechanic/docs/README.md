# Documentație myMechanic

Această documentație conține ghiduri, implementări și informații de depanare pentru aplicația myMechanic.

## Structura Documentației

### 📁 implementation/
Documentație pentru implementarea funcționalităților aplicației:
- `VEHICLE_DETAIL_IMPLEMENTATION.md` - Implementarea detaliilor vehiculului
- `VEHICLE_MAINTENANCE_IMPLEMENTATION.md` - Implementarea sistemului de întreținere
- `VEHICLE_SHARING_IMPLEMENTATION.md` - Implementarea partajării vehiculelor
- `IMAGE_UPLOAD_SUMMARY.md` - Rezumat încărcare imagini
- `VEHICLE_IMAGE_SETUP.md` - Configurare imagini vehicule
- `VEHICLE_DETAIL_SCREEN.md` - Ecranul de detalii vehicul
- `PLATFORM_ADAPTIVE_UI.md` - UI adaptiv pentru platforme
- `ADAPTIVE_UI_SUMMARY.md` - Rezumat UI adaptiv
- `ROLE_BASED_NAVIGATION.md` - Navigare bazată pe roluri

### 🔧 fixes/
Documentație pentru rezolvări de probleme și bug-uri:
- **`QUICK_FIX_VEHICLE_RLS.md`** - 🚨 Fix urgent pentru eroarea de adăugare vehicul
- **`FIX_VEHICLE_RLS_INSERT.md`** - Fix complet RLS pentru vehicule
- `FIX_ADD_MAINTENANCE_BUTTON.md` - Fix buton adăugare întreținere
- `FIX_RLS_GUIDE.md` - Ghid pentru Row Level Security
- `FIX_USER_VEHICLES_TABLE.md` - Fix tabel vehicule utilizator
- `FIX_VEHICLE_ERROR.md` - Fix erori vehicul
- `VEHICLE_ID_FIX.md` - Fix ID vehicul
- `VIN_UNIQUENESS_FIX.md` - Fix unicitate VIN
- `SIGNIN_BUTTON_FIX.md` - Fix buton sign in
- `EMAIL_CONFIRMATION_FIX.md` - Fix confirmare email
- `SCAFFOLD_FIX.md` - Fix scaffold
- `FINAL_VIN_FIX_SUMMARY.md` - Rezumat final fix VIN
- `EMERGENCY_FIX_INSTRUCTIONS.md` - Instrucțiuni fix urgență

### 🔍 troubleshooting/
Ghiduri pentru depanare și rezolvarea problemelor:
- `TROUBLESHOOTING.md` - Ghid general de depanare
- `VIN_ERROR_TROUBLESHOOTING.md` - Depanare erori VIN
- `DUPLICATE_VIN_ERROR_HANDLING.md` - Gestionare erori VIN duplicate

### 📘 guides/
Ghiduri și documentație generală:
- `VEHICLE_SHARING_QUICK_SUMMARY.md` - Rezumat rapid partajare vehicule

### 💾 database/
Documentație despre baza de date și migrări:
- `MIGRATION_GUIDE.md` - Ghid migrări baza de date
- `MIGRATIONS_INDEX.md` - Index migrări
- `MIGRATIONS_SUMMARY.md` - Rezumat migrări
- **`sql/`** - Scripturi SQL pentru baza de date
  - Vezi [SQL Scripts Index](database/sql/README.md) pentru detalii

### 🔨 development/
Documentație pentru dezvoltatori:
- **`CODE_MODULARIZATION.md`** - Raport modularizare cod
  - Structura modulară a aplicației
  - Principii de modularizare
  - Ghid pentru dezvoltare viitoare
  - Best practices pentru cod nou
- **`WIDGET_INDEX.md`** - Index complet widget-uri
  - Catalog de toate widget-urile modularizate
  - Exemple de utilizare
  - Best practices pentru crearea de widget-uri noi

## Cum să folosești această documentație

1. **Pentru implementare nouă**: Consultă directorul `implementation/`
2. **Pentru rezolvarea unui bug**: Verifică directorul `fixes/`
3. **Pentru probleme**: Caută în `troubleshooting/`
4. **Pentru baza de date**: Vezi `database/`
5. **Pentru ghiduri rapide**: Consultă `guides/`
6. **Pentru modularizare cod**: Vezi `CODE_MODULARIZATION.md` în root

## Navigare Rapidă pentru Dezvoltatori

### 📋 Vreau să...
- **Adaug un feature nou** → Vezi [`development/CODE_MODULARIZATION.md`](development/CODE_MODULARIZATION.md)
- **Creez un widget nou** → Vezi [`development/WIDGET_INDEX.md`](development/WIDGET_INDEX.md)
- **Înțeleg arhitectura** → Vezi secțiunea "Structura Codului" mai jos
- **Rezolv o eroare** → Caută în `fixes/` sau `troubleshooting/`
- **Lucrez cu baza de date** → Vezi `database/`
- **Implementez o funcționalitate** → Caută în `implementation/`

---

## Structura Codului

### Modularizare
Aplicația folosește o arhitectură modulară pentru ușurință în întreținere:
- **Screens** - Ecrane principale care orchestrează widget-uri
- **Widgets** - Componente reutilizabile organizate pe feature-uri
- **Providers** - State management și business logic
- **Services** - Integrări externe (Supabase, etc.)
- **Models** - Structuri de date

Pentru detalii complete, vezi [`development/CODE_MODULARIZATION.md`](development/CODE_MODULARIZATION.md).

## Contribuție

Când adaugi documentație nouă, respectă structura existentă și plasează fișierul în directorul corespunzător.
