# SQL Scripts Index

Această directoare conține scripturi SQL pentru configurarea și întreținerea bazei de date.

## 📄 Scripturi Disponibile

### Schema și Configurare Inițială
- **`database_schema.sql`** - Schema completă a bazei de date
  - Tabele pentru utilizatori, vehicule, întreținere, reminder-uri
  - Trigger-uri și funcții
  - Politici RLS (Row Level Security)

- **`vehicle_sharing_schema.sql`** - Schema pentru partajarea vehiculelor
  - Tabel `shared_vehicles` pentru gestionarea partajărilor
  - Politici RLS pentru acces controlat

### Fix-uri și Patch-uri
- **`fix_rls_policies.sql`** - Corecții pentru politicile Row Level Security
  - Actualizări pentru acces securizat la date
  
- **`fix_vehicle_rls.sql`** - Fix-uri specifice pentru RLS pe tabelul vehicles
  - Politici de acces la vehicule

- **`EMERGENCY_FIX.sql`** - Script de urgență pentru probleme critice
  - Să fie folosit doar în caz de urgență

## 🚀 Cum să Folosești Scripturile

### Configurare Inițială

1. **Prima instalare** - Rulează în ordine:
   ```sql
   -- 1. Schema principală
   database_schema.sql
   
   -- 2. Schema pentru partajare
   vehicle_sharing_schema.sql
   ```

2. **Aplicare fix-uri** - Dacă întâmpini probleme cu accesul:
   ```sql
   fix_rls_policies.sql
   fix_vehicle_rls.sql
   ```

### Prin Supabase Dashboard

1. Accesează proiectul Supabase
2. Navighează la **SQL Editor**
3. Copiază conținutul scriptului
4. Rulează scriptul
5. Verifică rezultatele

### Prin CLI

```bash
# Conectează-te la proiect
supabase link --project-ref your-project-ref

# Aplică migrări
supabase db push
```

## ⚠️ Atenție

- **Backup**: Fă întotdeauna backup înainte de a rula scripturi SQL
- **Testare**: Testează scripturile pe un mediu de development mai întâi
- **Ordine**: Respectă ordinea de rulare a scripturilor
- **Emergency Fix**: Folosește `EMERGENCY_FIX.sql` doar când este absolut necesar

## 📋 Migrări

Pentru informații despre migrări, vezi:
- `MIGRATION_GUIDE.md` - Ghid complet de migrări
- `MIGRATIONS_INDEX.md` - Index al migrărilor
- `MIGRATIONS_SUMMARY.md` - Rezumat migrări

## 🔗 Resurse

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
