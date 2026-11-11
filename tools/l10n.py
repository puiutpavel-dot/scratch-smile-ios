#!/usr/bin/env python3
"""Textele aplicației în 7 limbi. Rulează `python3 tools/l10n.py` din rădăcina proiectului
după orice modificare: rescrie Sources/<limbă>.lproj/Localizable.strings.

Ordinea limbilor în fiecare rând: ro, en, es, fr, de, it, pt.
În texte, %@ (sau %1$@, %2$@) e locul unde aplicația pune un număr sau un nume.
"""
import os

LANGS = ["ro", "en", "es", "fr", "de", "it", "pt"]

T = {
    # --- lozul
    "cover.scratch": ["RĂZUIEȘTE AICI", "SCRATCH HERE", "RASCA AQUÍ", "GRATTE ICI", "HIER RUBBELN", "GRATTA QUI", "RASPE AQUI"],
    "cover.tap": ["ATINGE AICI", "TAP HERE", "TOCA AQUÍ", "TOUCHE ICI", "HIER TIPPEN", "TOCCA QUI", "TOQUE AQUI"],
    "lucky.number": ["🍀 Numărul tău norocos: %@", "🍀 Your lucky number: %@", "🍀 Tu número de la suerte: %@", "🍀 Ton numéro porte-bonheur : %@", "🍀 Deine Glückszahl: %@", "🍀 Il tuo numero fortunato: %@", "🍀 Seu número da sorte: %@"],
    "ticket.empty": ["Cumpără un loz ca să joci", "Buy a ticket to play", "Compra un boleto para jugar", "Achète un ticket pour jouer", "Kaufe ein Los, um zu spielen", "Compra un biglietto per giocare", "Compre uma raspadinha para jogar"],
    "share.friend": ["Trimite unui prieten", "Send to a friend", "Enviar a un amigo", "Envoyer à un ami", "An Freunde senden", "Invia a un amico", "Enviar a um amigo"],
    "share.messages": ["Trimite prin Mesaje", "Send via Messages", "Enviar por Mensajes", "Envoyer par Messages", "Per Nachrichten senden", "Invia con Messaggi", "Enviar por Mensagens"],
    "share.tagline": ["%@ · răzuiește și tu", "%@ · scratch one too", "%@ · rasca tú también", "%@ · gratte toi aussi", "%@ · rubbel mit", "%@ · gratta anche tu", "%@ · raspe você também"],
    "buy.free": ["🎟️ Răzuiește lozul gratuit", "🎟️ Scratch your free ticket", "🎟️ Rasca tu boleto gratis", "🎟️ Gratte ton ticket gratuit", "🎟️ Gratis-Los rubbeln", "🎟️ Gratta il biglietto gratis", "🎟️ Raspe a raspadinha grátis"],
    "buy.paid": ["Cumpără loz (%@ 💰)", "Buy ticket (%@ 💰)", "Comprar boleto (%@ 💰)", "Acheter un ticket (%@ 💰)", "Los kaufen (%@ 💰)", "Compra biglietto (%@ 💰)", "Comprar raspadinha (%@ 💰)"],
    "welcome": ["Primul loz e din partea casei. Răzuiește-l cu degetul!", "Your first ticket is on the house. Scratch it with your finger!", "El primer boleto invita la casa. ¡Ráscalo con el dedo!", "Le premier ticket est offert par la maison. Gratte-le avec le doigt !", "Das erste Los geht aufs Haus. Rubble es mit dem Finger frei!", "Il primo biglietto lo offre la casa. Grattalo con il dito!", "A primeira raspadinha é por conta da casa. Raspe com o dedo!"],
    "win": ["Ai câștigat %@ 💰! 🎉", "You won %@ 💰! 🎉", "¡Has ganado %@ 💰! 🎉", "Tu as gagné %@ 💰 ! 🎉", "Du hast %@ 💰 gewonnen! 🎉", "Hai vinto %@ 💰! 🎉", "Você ganhou %@ 💰! 🎉"],

    # --- tipuri de lozuri
    "ticket.bronze": ["Lozul de Bronz", "Bronze Ticket", "Boleto de Bronce", "Ticket Bronze", "Bronzelos", "Biglietto di Bronzo", "Raspadinha de Bronze"],
    "ticket.silver": ["Lozul de Argint", "Silver Ticket", "Boleto de Plata", "Ticket Argent", "Silberlos", "Biglietto d'Argento", "Raspadinha de Prata"],
    "ticket.gold": ["Lozul de Aur", "Gold Ticket", "Boleto de Oro", "Ticket Or", "Goldlos", "Biglietto d'Oro", "Raspadinha de Ouro"],
    "ticket.lucky": ["Numărul Norocos", "Lucky Number", "Número de la Suerte", "Numéro Porte-Bonheur", "Glückszahl", "Numero Fortunato", "Número da Sorte"],
    "ticket.dec1": ["Lozul de 1 Decembrie", "Romania Day Ticket", "Boleto del Día de Rumanía", "Ticket Fête de la Roumanie", "Rumänien-Tag-Los", "Biglietto Festa della Romania", "Raspadinha Dia da Romênia"],
    "ticket.christmas": ["Lozul de Crăciun", "Christmas Ticket", "Boleto de Navidad", "Ticket de Noël", "Weihnachtslos", "Biglietto di Natale", "Raspadinha de Natal"],
    "ticket.easter": ["Lozul de Paște", "Easter Ticket", "Boleto de Pascua", "Ticket de Pâques", "Osterlos", "Biglietto di Pasqua", "Raspadinha de Páscoa"],

    # --- lobby
    "lobby.bonus.claim": ["🎁 Bonus ziua %1$@ din 7 (+%2$@ 💰)", "🎁 Day %1$@ of 7 bonus (+%2$@ 💰)", "🎁 Bono día %1$@ de 7 (+%2$@ 💰)", "🎁 Bonus jour %1$@ sur 7 (+%2$@ 💰)", "🎁 Bonus Tag %1$@ von 7 (+%2$@ 💰)", "🎁 Bonus giorno %1$@ di 7 (+%2$@ 💰)", "🎁 Bônus dia %1$@ de 7 (+%2$@ 💰)"],
    "lobby.bonus.taken": ["Bonus luat azi (ziua %@ din 7). Revino mâine!", "Bonus claimed today (day %@ of 7). Come back tomorrow!", "Bono de hoy cobrado (día %@ de 7). ¡Vuelve mañana!", "Bonus du jour récupéré (jour %@ sur 7). Reviens demain !", "Bonus heute abgeholt (Tag %@ von 7). Komm morgen wieder!", "Bonus di oggi riscosso (giorno %@ di 7). Torna domani!", "Bônus de hoje resgatado (dia %@ de 7). Volte amanhã!"],
    "lobby.free": ["🎟️ Loz de Bronz gratuit", "🎟️ Free Bronze Ticket", "🎟️ Boleto de Bronce gratis", "🎟️ Ticket Bronze gratuit", "🎟️ Gratis-Bronzelos", "🎟️ Biglietto di Bronzo gratis", "🎟️ Raspadinha de Bronze grátis"],
    "lobby.free.wait": ["Următorul loz gratuit în %@", "Next free ticket in %@", "Próximo boleto gratis en %@", "Prochain ticket gratuit dans %@", "Nächstes Gratis-Los in %@", "Prossimo biglietto gratis tra %@", "Próxima raspadinha grátis em %@"],
    "lobby.leaderboard": ["🏆 Clasament", "🏆 Leaderboard", "🏆 Clasificación", "🏆 Classement", "🏆 Bestenliste", "🏆 Classifica", "🏆 Classificação"],
    "lobby.messages": ["💬 Mesaje", "💬 Messages", "💬 Mensajes", "💬 Messages", "💬 Nachrichten", "💬 Messaggi", "💬 Mensagens"],
    "lobby.choose": ["Alege un loz", "Pick a ticket", "Elige un boleto", "Choisis un ticket", "Wähle ein Los", "Scegli un biglietto", "Escolha uma raspadinha"],
    "lobby.limited": ["EDIȚIE LIMITATĂ", "LIMITED EDITION", "EDICIÓN LIMITADA", "ÉDITION LIMITÉE", "LIMITIERTE EDITION", "EDIZIONE LIMITATA", "EDIÇÃO LIMITADA"],
    "lobby.ticket.info": ["%1$@ 💰 · premiu maxim %2$@ 💰", "%1$@ 💰 · top prize %2$@ 💰", "%1$@ 💰 · premio máximo %2$@ 💰", "%1$@ 💰 · gain maximum %2$@ 💰", "%1$@ 💰 · Höchstgewinn %2$@ 💰", "%1$@ 💰 · premio massimo %2$@ 💰", "%1$@ 💰 · prêmio máximo %2$@ 💰"],
    "lobby.disclaimer": ["Monedele sunt virtuale și nu pot fi schimbate în bani sau premii.", "Coins are virtual and cannot be exchanged for money or prizes.", "Las monedas son virtuales y no se pueden canjear por dinero ni premios.", "Les pièces sont virtuelles et ne peuvent pas être échangées contre de l'argent ou des lots.", "Die Münzen sind virtuell und können nicht gegen Geld oder Preise eingetauscht werden.", "Le monete sono virtuali e non possono essere convertite in denaro o premi.", "As moedas são virtuais e não podem ser trocadas por dinheiro ou prêmios."],

    # --- ecranul de mesaje
    "messages.title": ["Mesaje", "Messages", "Mensajes", "Messages", "Nachrichten", "Messaggi", "Mensagens"],
    "messages.collection": ["Colecția ta: %1$@ din %2$@", "Your collection: %1$@ of %2$@", "Tu colección: %1$@ de %2$@", "Ta collection : %1$@ sur %2$@", "Deine Sammlung: %1$@ von %2$@", "La tua collezione: %1$@ di %2$@", "Sua coleção: %1$@ de %2$@"],
    "messages.locked": ["🔒 Încă nedescoperit", "🔒 Not discovered yet", "🔒 Aún sin descubrir", "🔒 Pas encore découvert", "🔒 Noch nicht entdeckt", "🔒 Non ancora scoperto", "🔒 Ainda não descoberto"],
    "messages.contact": ["Scrie-ne", "Contact us", "Escríbenos", "Écris-nous", "Schreib uns", "Scrivici", "Fale conosco"],
    "messages.contact.link": ["✉️ Trimite o sugestie sau o problemă", "✉️ Send a suggestion or report a problem", "✉️ Envía una sugerencia o un problema", "✉️ Envoie une suggestion ou un problème", "✉️ Vorschlag oder Problem senden", "✉️ Invia un suggerimento o un problema", "✉️ Envie uma sugestão ou um problema"],

    # --- notificări
    "notif.free.title": ["🎟️ Lozul tău gratuit e gata", "🎟️ Your free ticket is ready", "🎟️ Tu boleto gratis está listo", "🎟️ Ton ticket gratuit est prêt", "🎟️ Dein Gratis-Los ist bereit", "🎟️ Il tuo biglietto gratis è pronto", "🎟️ Sua raspadinha grátis está pronta"],
    "notif.free.body": ["Vino să-l răzuiești. Poate azi e ziua ta!", "Come scratch it. Today might be your day!", "Ven a rascarlo. ¡Quizá hoy sea tu día!", "Viens le gratter. C'est peut-être ton jour !", "Komm und rubble es frei. Vielleicht ist heute dein Tag!", "Vieni a grattarlo. Magari oggi è il tuo giorno!", "Venha raspar. Talvez hoje seja o seu dia!"],
    "notif.streak.title": ["🔥 Nu-ți pierde seria: ziua %@", "🔥 Don't lose your streak: day %@", "🔥 No pierdas tu racha: día %@", "🔥 Ne perds pas ta série : jour %@", "🔥 Verlier deine Serie nicht: Tag %@", "🔥 Non perdere la serie: giorno %@", "🔥 Não perca a sequência: dia %@"],
    "notif.streak.body": ["Bonusul de azi te așteaptă. Mâine o iei de la capăt!", "Today's bonus is waiting. Tomorrow you start over!", "El bono de hoy te espera. ¡Mañana empiezas de cero!", "Le bonus du jour t'attend. Demain, tu repars de zéro !", "Der heutige Bonus wartet. Morgen fängst du von vorn an!", "Il bonus di oggi ti aspetta. Domani ricominci da capo!", "O bônus de hoje está esperando. Amanhã você recomeça do zero!"],

    # --- statistici și realizări
    "stats.title": ["Statistici", "Statistics", "Estadísticas", "Statistiques", "Statistik", "Statistiche", "Estatísticas"],
    "stats.tickets": ["Lozuri răzuite", "Tickets scratched", "Boletos rascados", "Tickets grattés", "Gerubbelte Lose", "Biglietti grattati", "Raspadinhas raspadas"],
    "stats.total": ["Monede câștigate în total", "Total coins won", "Monedas ganadas en total", "Pièces gagnées au total", "Insgesamt gewonnene Münzen", "Monete vinte in totale", "Total de moedas ganhas"],
    "stats.biggest": ["Cel mai mare câștig", "Biggest win", "Mayor premio", "Plus gros gain", "Größter Gewinn", "Vincita più alta", "Maior prêmio"],
    "stats.jackpots": ["Jackpoturi", "Jackpots", "Jackpots", "Jackpots", "Jackpots", "Jackpot", "Jackpots"],
    "stats.streak": ["Cea mai lungă serie (zile)", "Longest streak (days)", "Racha más larga (días)", "Plus longue série (jours)", "Längste Serie (Tage)", "Serie più lunga (giorni)", "Maior sequência (dias)"],
    "ach.title": ["Realizări", "Achievements", "Logros", "Succès", "Erfolge", "Obiettivi", "Conquistas"],
    "ach.jackpot.title": ["👑 Primul jackpot", "👑 First jackpot", "👑 Primer jackpot", "👑 Premier jackpot", "👑 Erster Jackpot", "👑 Primo jackpot", "👑 Primeiro jackpot"],
    "ach.jackpot.detail": ["Câștigă un jackpot", "Win a jackpot", "Gana un jackpot", "Gagne un jackpot", "Gewinne einen Jackpot", "Vinci un jackpot", "Ganhe um jackpot"],
    "ach.100.title": ["🎟️ Răzuitor de cursă lungă", "🎟️ Marathon scratcher", "🎟️ Rascador de fondo", "🎟️ Gratteur de fond", "🎟️ Dauerrubbler", "🎟️ Grattatore instancabile", "🎟️ Raspador de maratona"],
    "ach.100.detail": ["Răzuiește 100 de lozuri", "Scratch 100 tickets", "Rasca 100 boletos", "Gratte 100 tickets", "Rubble 100 Lose frei", "Gratta 100 biglietti", "Raspe 100 raspadinhas"],
    "ach.streak.title": ["🔥 Săptămâna perfectă", "🔥 Perfect week", "🔥 Semana perfecta", "🔥 Semaine parfaite", "🔥 Perfekte Woche", "🔥 Settimana perfetta", "🔥 Semana perfeita"],
    "ach.streak.detail": ["Ia bonusul 7 zile la rând", "Claim the bonus 7 days in a row", "Cobra el bono 7 días seguidos", "Récupère le bonus 7 jours de suite", "Hol dir den Bonus 7 Tage in Folge", "Riscuoti il bonus 7 giorni di fila", "Resgate o bônus 7 dias seguidos"],
    "ach.msgs.title": ["💬 Înțeleptul", "💬 The Sage", "💬 El Sabio", "💬 Le Sage", "💬 Der Weise", "💬 Il Saggio", "💬 O Sábio"],
    "ach.msgs.detail": ["Descoperă toate mesajele", "Discover every message", "Descubre todos los mensajes", "Découvre tous les messages", "Entdecke alle Nachrichten", "Scopri tutti i messaggi", "Descubra todas as mensagens"],

    # --- setări
    "settings.title": ["Setări", "Settings", "Ajustes", "Réglages", "Einstellungen", "Impostazioni", "Ajustes"],
    "settings.sound": ["Sunet", "Sound", "Sonido", "Son", "Ton", "Suono", "Som"],
    "settings.haptics": ["Vibrație", "Vibration", "Vibración", "Vibration", "Vibration", "Vibrazione", "Vibração"],
    "settings.tap": ["Atinge ca să dezvălui", "Tap to reveal", "Toca para revelar", "Toucher pour révéler", "Tippen zum Aufdecken", "Tocca per rivelare", "Toque para revelar"],
    "settings.tap.footer": ["Lozul se dezvăluie la o singură atingere, fără răzuit cu degetul.", "The ticket is revealed with a single tap, no scratching needed.", "El boleto se revela con un solo toque, sin rascar.", "Le ticket se révèle d'un simple toucher, sans gratter.", "Das Los wird mit einem Tippen aufgedeckt, ganz ohne Rubbeln.", "Il biglietto si rivela con un solo tocco, senza grattare.", "A raspadinha é revelada com um toque, sem raspar."],
}

# Mesajele de la lozurile necâștigătoare: 0–9 glume, 10–19 sfaturi despre viață.
MESSAGES = [
    ["Lozul ăsta a fost la dietă: zero premii. 🥗", "This ticket was on a diet: zero prizes. 🥗", "Este boleto estaba a dieta: cero premios. 🥗", "Ce ticket était au régime : zéro gain. 🥗", "Dieses Los war auf Diät: null Gewinne. 🥗", "Questo biglietto era a dieta: zero premi. 🥗", "Esta raspadinha estava de dieta: zero prêmios. 🥗"],
    ["Ai câștigat experiență. Din păcate, nu se acceptă la magazin. 😅", "You won experience. Sadly, shops don't accept it. 😅", "Has ganado experiencia. Por desgracia, no la aceptan en las tiendas. 😅", "Tu as gagné de l'expérience. Hélas, les magasins ne l'acceptent pas. 😅", "Du hast Erfahrung gewonnen. Leider nimmt sie kein Laden an. 😅", "Hai vinto esperienza. Purtroppo nei negozi non la accettano. 😅", "Você ganhou experiência. Pena que as lojas não aceitam. 😅"],
    ["Premiul a plecat în concediu. Revine el. 🏖️", "The prize is on holiday. It'll be back. 🏖️", "El premio se fue de vacaciones. Ya volverá. 🏖️", "Le gain est parti en vacances. Il reviendra. 🏖️", "Der Gewinn ist im Urlaub. Er kommt wieder. 🏖️", "Il premio è andato in vacanza. Tornerà. 🏖️", "O prêmio saiu de férias. Ele volta. 🏖️"],
    ["Felicitări! Ai găsit unul dintre lozurile fără premiu. Sunt destule. 🙃", "Congrats! You found one of the tickets with no prize. There are plenty. 🙃", "¡Enhorabuena! Encontraste uno de los boletos sin premio. Hay bastantes. 🙃", "Bravo ! Tu as trouvé un des tickets sans gain. Il y en a plein. 🙃", "Glückwunsch! Du hast eines der Lose ohne Gewinn gefunden. Davon gibt es viele. 🙃", "Complimenti! Hai trovato uno dei biglietti senza premio. Ce ne sono tanti. 🙃", "Parabéns! Você achou uma das raspadinhas sem prêmio. Tem bastante. 🙃"],
    ["Degetul tău a muncit degeaba, dar măcar a făcut sport. 💪", "Your finger worked for nothing, but at least it got a workout. 💪", "Tu dedo trabajó en vano, pero al menos hizo ejercicio. 💪", "Ton doigt a travaillé pour rien, mais au moins il a fait du sport. 💪", "Dein Finger hat umsonst gearbeitet, aber immerhin Sport gemacht. 💪", "Il tuo dito ha lavorato per niente, ma almeno ha fatto sport. 💪", "Seu dedo trabalhou à toa, mas pelo menos fez exercício. 💪"],
    ["Nimic aici. Nici măcar o scuză. 🤷", "Nothing here. Not even an excuse. 🤷", "Nada por aquí. Ni siquiera una excusa. 🤷", "Rien ici. Même pas une excuse. 🤷", "Nichts hier. Nicht mal eine Ausrede. 🤷", "Niente qui. Nemmeno una scusa. 🤷", "Nada aqui. Nem uma desculpa. 🤷"],
    ["Lozul zice: nu ești tu de vină, eu sunt. 💔", "The ticket says: it's not you, it's me. 💔", "El boleto dice: no eres tú, soy yo. 💔", "Le ticket dit : ce n'est pas toi, c'est moi. 💔", "Das Los sagt: Es liegt nicht an dir, es liegt an mir. 💔", "Il biglietto dice: non sei tu, sono io. 💔", "A raspadinha diz: o problema não é você, sou eu. 💔"],
    ["Atâta răzuit și nici măcar o cireașă. 🍒", "All that scratching and not even a cherry. 🍒", "Tanto rascar y ni una cereza. 🍒", "Tout ce grattage et même pas une cerise. 🍒", "So viel Rubbeln und nicht mal eine Kirsche. 🍒", "Tanto grattare e nemmeno una ciliegia. 🍒", "Tanta raspagem e nem uma cereja. 🍒"],
    ["Monedele tale au plecat într-o lume mai bună. 🕊️", "Your coins have gone to a better place. 🕊️", "Tus monedas se han ido a un lugar mejor. 🕊️", "Tes pièces sont parties vers un monde meilleur. 🕊️", "Deine Münzen sind jetzt an einem besseren Ort. 🕊️", "Le tue monete sono andate in un posto migliore. 🕊️", "Suas moedas foram para um lugar melhor. 🕊️"],
    ["Dacă ghinionul ar fi sport, azi luai aurul. 🥇", "If bad luck were a sport, you'd take gold today. 🥇", "Si la mala suerte fuera deporte, hoy te llevabas el oro. 🥇", "Si la malchance était un sport, tu aurais l'or aujourd'hui. 🥇", "Wäre Pech eine Sportart, hättest du heute Gold. 🥇", "Se la sfortuna fosse uno sport, oggi vinceresti l'oro. 🥇", "Se azar fosse esporte, hoje o ouro era seu. 🥇"],
    ["Sfatul zilei: bea un pahar cu apă. Lozul poate aștepta. 💧", "Tip of the day: drink a glass of water. The ticket can wait. 💧", "Consejo del día: bebe un vaso de agua. El boleto puede esperar. 💧", "Conseil du jour : bois un verre d'eau. Le ticket peut attendre. 💧", "Tipp des Tages: Trink ein Glas Wasser. Das Los kann warten. 💧", "Consiglio del giorno: bevi un bicchiere d'acqua. Il biglietto può aspettare. 💧", "Dica do dia: beba um copo d'água. A raspadinha pode esperar. 💧"],
    ["Sun-o pe mama. Ăla e câștig sigur. 📞", "Call your mom. That's a guaranteed win. 📞", "Llama a tu madre. Eso sí es un premio seguro. 📞", "Appelle ta mère. Ça, c'est un gain assuré. 📞", "Ruf deine Mutter an. Das ist ein sicherer Gewinn. 📞", "Chiama tua mamma. Quella sì che è una vincita sicura. 📞", "Ligue para sua mãe. Esse é prêmio garantido. 📞"],
    ["Nu compara viața ta cu lozul altuia. 🌱", "Don't compare your life to someone else's ticket. 🌱", "No compares tu vida con el boleto de otro. 🌱", "Ne compare pas ta vie au ticket d'un autre. 🌱", "Vergleiche dein Leben nicht mit dem Los eines anderen. 🌱", "Non paragonare la tua vita al biglietto di un altro. 🌱", "Não compare a sua vida com a raspadinha dos outros. 🌱"],
    ["Cine se culcă devreme câștigă măcar somnul. 😴", "Go to bed early and you'll at least win some sleep. 😴", "Quien se acuesta temprano gana, al menos, sueño. 😴", "Qui se couche tôt gagne au moins du sommeil. 😴", "Wer früh schlafen geht, gewinnt wenigstens Schlaf. 😴", "Chi va a letto presto vince almeno il sonno. 😴", "Quem dorme cedo ganha, pelo menos, sono. 😴"],
    ["Norocul și-l mai face omul și cu mâna lui. Ieși la o plimbare. 🚶", "Sometimes you make your own luck. Go for a walk. 🚶", "La suerte a veces se la hace uno mismo. Sal a dar un paseo. 🚶", "La chance, on se la fabrique parfois soi-même. Va faire un tour. 🚶", "Manchmal macht man sich sein Glück selbst. Geh spazieren. 🚶", "A volte la fortuna te la costruisci da solo. Esci a fare due passi. 🚶", "Às vezes a gente faz a própria sorte. Saia para caminhar. 🚶"],
    ["Un zâmbet nu costă nicio monedă. Dă unul azi. 😊", "A smile costs zero coins. Give one away today. 😊", "Una sonrisa no cuesta ni una moneda. Regala una hoy. 😊", "Un sourire ne coûte aucune pièce. Offres-en un aujourd'hui. 😊", "Ein Lächeln kostet keine einzige Münze. Verschenk heute eins. 😊", "Un sorriso non costa nemmeno una moneta. Regalane uno oggi. 😊", "Um sorriso não custa nenhuma moeda. Dê um hoje. 😊"],
    ["Lucrurile bune vin încet. Lozurile proaste vin repede. ⏳", "Good things come slowly. Bad tickets come fast. ⏳", "Lo bueno llega despacio. Los boletos malos llegan rápido. ⏳", "Les bonnes choses arrivent lentement. Les mauvais tickets arrivent vite. ⏳", "Gute Dinge kommen langsam. Schlechte Lose kommen schnell. ⏳", "Le cose belle arrivano piano. I biglietti sfortunati arrivano in fretta. ⏳", "Coisas boas vêm devagar. Raspadinhas ruins vêm rápido. ⏳"],
    ["Spune-i cuiva că îl apreciezi. Premiu garantat. ❤️", "Tell someone you appreciate them. Prize guaranteed. ❤️", "Dile a alguien que lo aprecias. Premio garantizado. ❤️", "Dis à quelqu'un que tu l'apprécies. Gain garanti. ❤️", "Sag jemandem, dass du ihn schätzt. Gewinn garantiert. ❤️", "Di' a qualcuno che lo apprezzi. Premio garantito. ❤️", "Diga a alguém que você o admira. Prêmio garantido. ❤️"],
    ["Întinde-te puțin. Spatele tău nu e monedă virtuală. 🧘", "Have a stretch. Your back isn't a virtual coin. 🧘", "Estírate un poco. Tu espalda no es una moneda virtual. 🧘", "Étire-toi un peu. Ton dos n'est pas une pièce virtuelle. 🧘", "Streck dich mal. Dein Rücken ist keine virtuelle Münze. 🧘", "Fai un po' di stretching. La tua schiena non è una moneta virtuale. 🧘", "Alongue-se um pouco. Suas costas não são moeda virtual. 🧘"],
    ["Ai pierdut un loz, nu ziua. Fă ceva frumos cu ea. ☀️", "You lost a ticket, not the day. Do something nice with it. ☀️", "Perdiste un boleto, no el día. Haz algo bonito con él. ☀️", "Tu as perdu un ticket, pas ta journée. Fais-en quelque chose de beau. ☀️", "Du hast ein Los verloren, nicht den Tag. Mach etwas Schönes daraus. ☀️", "Hai perso un biglietto, non la giornata. Fanne qualcosa di bello. ☀️", "Você perdeu uma raspadinha, não o dia. Faça algo bom com ele. ☀️"],
]


def main():
    table = dict(T)
    for index, row in enumerate(MESSAGES):
        table[f"msg.{index}"] = row
    for key, row in table.items():
        assert len(row) == len(LANGS), key
        marks = {tuple(sorted(p for p in ("%@", "%1$@", "%2$@") if p in text)) for text in row}
        assert len(marks) == 1, f"{key}: locurile pentru valori diferă între limbi"

    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Sources")
    for i, lang in enumerate(LANGS):
        folder = os.path.join(root, f"{lang}.lproj")
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, "Localizable.strings"), "w", encoding="utf-8") as f:
            for key, row in table.items():
                value = row[i].replace("\\", "\\\\").replace('"', '\\"')
                f.write(f'"{key}" = "{value}";\n')
    print(f"{len(table)} texte × {len(LANGS)} limbi; mesaje: {len(MESSAGES)}")


if __name__ == "__main__":
    main()
