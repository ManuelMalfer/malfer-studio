# Malfer Studio

Sito di studio.malfer.it (GitHub Pages, repository `ManuelMalfer/malfer-studio`).

## Aggiungere le foto

1. Metti i JPG nella cartella `foto-originali` (NON va su GitHub), in sottocartelle che diventano le categorie
   (es. `foto-originali\Piatti`, `foto-originali\Sale`). Il nome del file diventa la didascalia.
   `foto-originali\copertina.jpg` = foto grande in apertura, `foto-originali\manuel.jpg` = foto in "Chi sono".
2. Da PowerShell, nella cartella del sito:
   `powershell -ExecutionPolicy Bypass -File strumenti\prepara-foto.ps1`
3. Pubblica la cartella `foto` (commit + push, oppure "Add files via upload" su GitHub).

Senza foto il sito funziona lo stesso: la sezione "Lavori" resta nascosta.

## Numero WhatsApp

In `index.html`, in fondo, la riga `const WHATSAPP = "";` → es. `"393401234567"`. Vuoto = niente tasti WhatsApp.

## Check-up gratuito

`studio.malfer.it/checkup/` (non indicizzata, nessun link dal sito): modulo da compilare dal telefono nel locale, report in PDF e riassunto su WhatsApp. I check-up restano salvati solo nel browser del dispositivo usato. Voci e consigli: costante `SEZIONI` in `checkup/index.html`.
