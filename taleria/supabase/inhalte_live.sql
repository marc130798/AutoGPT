-- Inhalte für die LIVE-Datenbank (geprüfter Import, CLAUDE.md Abschnitt 10).
-- Automatisch erzeugt aus content/stufe1/*.json mit: dart run tool/build_seed.dart
-- Nicht von Hand ändern, sondern die Inhaltsdateien bearbeiten und neu erzeugen.
-- Kinder sehen nur Inhalte mit "status": "freigegeben". Keine Test-Einstellungen.
-- Darf beliebig oft eingespielt werden. Veröffentlichte Inhalte schützt die Datenbank:
-- Pflichtstationen und Prüfungsfragen lassen sich korrigieren, aber nicht entfernen.

begin;

-- 1. Hafen von Taleria, Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/hafen')::uuid, 'hafen', 1, 1, 1, 0.5, 0.96, 'main', 'Hafen von Taleria', '{"goal":"Das Kind kennt Talo und Tala, weiß, was Geld ist, wie es entstanden ist, woher es kommt, warum Dinge etwas kosten und hat ein erstes Gefühl für Preise.","learn":["Was Geld ist und warum es Tauschen leichter macht","Woher Geld kommt und wie es früher aussah","Warum Dinge etwas kosten und wie du Preise liest"],"access":"free","badge":"Erster Landgang","real_life_task":{"title":"Preis-Detektiv","text":"Suche beim nächsten Einkauf drei Produkte, schätze vorher ihren Preis und vergleiche dann mit dem echten Preis. Überlege mit deinen Eltern, wer an einem davon alles mitverdient."},"teaser":{"scene":[{"speaker":"talo","text":"Seht ihr die Insel mit dem hohen Turm da vorn? Das ist die Tauschinsel. Dort gibt es gar kein Geld."},{"speaker":"tala","text":"Kein Geld? Wie bezahlen die denn ihr Mittagessen?"}],"next_slug":"tauschinsel","next_title":"Tauschinsel"}}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station1')::uuid, md5('taleria:stage1/hafen')::uuid, 10, 'practice', true, 50, '{"title":"Willkommen an Bord","number":1,"place":"Schiffssteg","goal":"Ankommen, Figuren und App kennen","minutes":"5 bis 8 Min.","kind":"onboarding"}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station2')::uuid, md5('taleria:stage1/hafen')::uuid, 20, 'quiz', true, 100, '{"title":"Was ist Geld?","number":2,"place":"Hafenbüro","goal":"Geld als Tauschmittel verstehen","minutes":"7 bis 10 Min.","scene":[{"speaker":"tala","text":"Ein Fischbrötchen, bitte! Ich bezahle mit meinem goldenen Halstuch."},{"speaker":"haendler","text":"Ein Halstuch? Tut mir leid, ich brauche Mehl für meine Brötchen.","name":"Händler"},{"speaker":"tala","text":"Mehl hab ich nicht. Und jetzt?"},{"speaker":"talo","text":"Genau für solche Fälle haben die Menschen das Geld erfunden."}],"lesson":[{"speaker":"talo","text":"Beim Tauschen muss jeder genau das haben, was der andere gerade braucht. Das klappt nur selten.","image":"story.hafen.2.1"},{"speaker":"talo","text":"Geld nimmt fast jeder an. Der Händler kann damit später sein Mehl kaufen.","image":"story.hafen.2.2"},{"speaker":"tala","text":"Und Geld kann man aufheben! Ein Fischbrötchen wird schlecht, ein Taler nicht.","image":"story.hafen.2.3"},{"speaker":"talo","text":"Mit Geld bekommt außerdem alles einen Preis in derselben Einheit. So kann man Preise vergleichen.","image":"story.hafen.2.4"}],"game":{"type":"choice","title":"Tausch-Spiel","description":"Tala versucht ohne Geld an ein Fischbrötchen zu kommen und merkt, wie umständlich Tauschen ist.","task":"Hilf Tala, ohne Geld an ein Fischbrötchen zu kommen.","rounds":[{"scene":[{"speaker":"haendler","text":"Ein Fischbrötchen gibt es nur gegen Mehl. Ein Halstuch brauche ich nicht.","name":"Händler"}],"question":"Was kann Tala tun?","options":[{"text":"Jemanden suchen, der Mehl hat und ein Halstuch will","good":true,"reply":"Gute Idee! Tala braucht jemanden, der genau ihr Halstuch will und Mehl hat."},{"text":"Dem Händler trotzdem das Halstuch geben","good":false,"reply":"Der Händler braucht Mehl für seine Brötchen. Mit einem Halstuch kann er nichts anfangen."}]},{"scene":[{"speaker":"bootsbauer","text":"Mehl habe ich. Aber ein Halstuch? Ich brauche Nägel für mein Boot.","name":"Bootsbauer"}],"question":"Was merkt Tala?","options":[{"text":"Tauschen ist umständlich: Jeder will etwas anderes.","good":true,"reply":"Genau. Tala müsste erst Nägel finden, dann Mehl, dann das Fischbrötchen. Das dauert!"},{"text":"Der Bootsbauer ist unfreundlich.","good":false,"reply":"Er ist gar nicht unfreundlich. Er braucht einfach etwas anderes als ein Halstuch."}]},{"scene":[{"speaker":"tala","text":"Puh, das ist ja eine Reise für ein einziges Fischbrötchen!"}],"question":"Womit hätte es viel einfacher geklappt?","options":[{"text":"Mit Geld","good":true,"reply":"Richtig! Geld nimmt fast jeder an. Der Händler kauft damit später sein Mehl."},{"text":"Mit einem größeren Halstuch","good":false,"reply":"Auch ein großes Halstuch hilft nicht, wenn der Händler Mehl braucht."},{"text":"Mit lauterem Rufen","good":false,"reply":"Lauter rufen ändert nichts daran, dass der Händler Mehl braucht."}]}],"done":{"speaker":"talo","text":"Siehst du? Mit Geld muss nicht jeder genau das haben, was der andere braucht."}},"estimate":{"speaker":"tala","question":"Was glaubst du: Wie viele Händler muss ich fragen, bis einer mein Halstuch nimmt?","kind":"wheel","min":0,"max":10,"start":3,"unit":"Händler","answer":0,"reveal":{"speaker":"talo","text":"Keiner! Niemand braucht gerade ein Halstuch. Genau deshalb haben die Menschen das Geld erfunden."}},"taps":[{"after":1,"kind":"drag","text":"Zieh Tala zum nächsten Stand.","image":"character.tala","done":"Auch hier will niemand ein Halstuch."},{"after":2,"kind":"drag","text":"Leg eine Münze statt des Halstuchs auf die Theke.","symbol":"muenze","done":"Die Münze nimmt der Händler gern!"}],"summary":{"speaker":"talo","text":"Geld ist ein Tauschmittel: Fast jeder nimmt es an, man kann es aufheben und damit Preise vergleichen."},"quiz":{"show":5}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q1')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Warum wollte der Händler Talas Halstuch nicht?', '["Er brauchte Mehl, kein Halstuch.","Das Halstuch war ihm zu klein.","Er mag die Farbe Gold nicht."]'::jsonb, 0, 'Beim Tauschen muss jeder genau das haben, was der andere gerade braucht. Das klappt nur selten.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q2')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Was ist der größte Vorteil von Geld gegenüber Tauschen?', '["Fast jeder nimmt es an.","Es ist schwerer als ein Halstuch.","Man kann es essen."]'::jsonb, 0, 'Weil fast jeder Geld annimmt, kann der Händler damit später sein Mehl kaufen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q3')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Tala bekommt heute 5 Taler und will erst nächste Woche etwas kaufen. Geht das?', '["Ja, Geld kann man aufheben.","Nein, Geld verschwindet am Abend.","Nur wenn Talo es erlaubt."]'::jsonb, 0, 'Ein Fischbrötchen wird schlecht, Geld kann man aufheben und später ausgeben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q4')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Ein Apfel kostet 50 Cent, eine Birne 80 Cent. Warum kannst du das so leicht vergleichen?', '["Beide Preise sind in derselben Währung angegeben.","Weil Birnen größer sind.","Weil Äpfel rot sind."]'::jsonb, 0, 'Mit Geld bekommt alles einen Preis in derselben Einheit, so sieht man sofort, was teurer ist.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q5')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Womit haben Menschen früher manchmal bezahlt, bevor es Münzen gab?', '["Mit Muscheln oder Salz","Mit Kreditkarten","Mit Smartphones"]'::jsonb, 0, 'Früher wurden seltene Dinge wie bestimmte Muscheln oder Salz als Zahlungsmittel genutzt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q6')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Der Bäcker nimmt deine Münzen, obwohl er sie nicht essen kann. Warum?', '["Weil er damit selbst bei anderen einkaufen kann.","Weil Münzen so schön glänzen.","Weil er Münzen sammelt."]'::jsonb, 0, 'Geld wandert weiter: Der Bäcker bezahlt damit zum Beispiel sein Mehl.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q7')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Warum ist ein 10-Euro-Schein etwas wert, obwohl er nur aus Papier ist?', '["Weil alle darauf vertrauen und ihn annehmen.","Weil er aus Gold gemacht ist.","Weil er so schön bunt ist."]'::jsonb, 0, 'Geld funktioniert, weil sich alle darauf verlassen, dass andere es auch annehmen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q8')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Was ist beim Tauschen ohne Geld besonders schwierig?', '["Jemanden zu finden, der genau das hat, was ich will, und genau das will, was ich habe.","Etwas in die Hand zu nehmen.","Freundlich zu sein."]'::jsonb, 0, 'Beide Seiten müssen gleichzeitig zufrieden sein. Mit Geld ist das viel einfacher.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q9')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Der Händler bekommt für ein Fischbrötchen 3 Taler. Was kann er damit tun?', '["Damit später bei jemand anderem Mehl kaufen","Nur Fischbrötchen kaufen","Gar nichts, Taler sind wertlos"]'::jsonb, 0, 'Mit Geld kann der Händler bei jedem einkaufen, der Geld annimmt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station2/q10')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Was macht Geld zu einem guten Tauschmittel?', '["Fast jeder nimmt es an und man kann es aufheben.","Es ist besonders bunt.","Man kann damit Fische fangen."]'::jsonb, 0, 'Ein gutes Tauschmittel wird von vielen angenommen und behält seinen Wert eine Weile.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station3')::uuid, md5('taleria:stage1/hafen')::uuid, 30, 'game', true, 100, '{"title":"Geld früher und heute","number":3,"place":"Altes Lagerhaus","goal":"Geld hat sich entwickelt, die Idee ist gleich geblieben","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Talo, hier im Lagerhaus stehen lauter alte Kisten!"},{"speaker":"talo","text":"Lass uns reinschauen. Muscheln, Salz, Metallstücke, alte Münzen und Scheine …"},{"speaker":"tala","text":"Das war alles mal Geld? Sogar Salz?"}],"lesson":[{"speaker":"talo","text":"Früher haben Menschen mit seltenen Dingen bezahlt, zum Beispiel mit bestimmten Muscheln oder mit Salz.","image":"story.hafen.3.1"},{"speaker":"talo","text":"Später kamen Münzen aus Metall. Sie halten lange und lassen sich leicht abzählen.","image":"story.hafen.3.2"},{"speaker":"tala","text":"Dann kamen Scheine aus Papier. Viel leichter als ein Sack voller Münzen!","image":"story.hafen.3.3"},{"speaker":"talo","text":"Heute bezahlen viele mit Karte oder Handy. Das Geld kommt dann von einem Konto. Die Idee ist gleich geblieben: Alle nehmen es an.","image":"story.hafen.3.4"}],"game":{"type":"order","title":"Zeitstrahl","description":"Ordne Muscheln, Münzen, Papiergeld sowie Karte und Handy auf einem Zeitstrahl von früher bis heute.","task":"Tippe die Dinge der Reihe nach an: zuerst das älteste Geld.","items":[{"text":"Muscheln und Salz","hint":"Ganz früher bezahlten Menschen mit seltenen Dingen aus der Natur."},{"text":"Münzen aus Metall","hint":"Münzen halten lange und lassen sich leicht abzählen."},{"text":"Scheine aus Papier","hint":"Scheine sind viel leichter als ein Sack voller Münzen."},{"text":"Karte und Handy","hint":"Heute kommt das Geld oft von einem Konto."}],"from":"Früher","to":"Heute","done":{"speaker":"talo","text":"Genau so! Das Geld hat sich verändert, die Idee ist gleich geblieben: Alle nehmen es an."}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie alt sind die ältesten Münzen der Welt?","kind":"slider","min":100,"max":5000,"step":100,"start":1000,"unit":"Jahre","unit_one":"Jahr","answer":2600,"reveal":{"speaker":"talo","text":"Die ältesten Münzen sind rund 2.600 Jahre alt. Sie stammen aus Lydien, einem alten Königreich in der heutigen Türkei."}},"taps":[{"after":1,"kind":"swipe","text":"Wisch den Staub von der alten Kiste.","symbol":"besen","done":"Darunter liegen Muscheln, Salz und alte Münzen."},{"after":3,"kind":"drag","text":"Zieh die Muschel an den Anfang des Zeitstrahls.","image":"item.muschel","done":"Richtig weit vorn: Muscheln waren eines der ersten Zahlungsmittel."}],"summary":{"speaker":"tala","text":"Geld hat sich verändert, aber es funktioniert immer gleich: Alle vertrauen darauf und nehmen es an."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station3/q1')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Was haben Menschen früher manchmal als Geld benutzt?', '["Seltene Muscheln","Plastiktüten","Kieselsteine, die überall herumliegen"]'::jsonb, 0, 'Als Geld taugt nur, was selten ist. Kieselsteine liegen überall, bestimmte Muscheln nicht.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station3/q2')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Warum waren Münzen praktischer als Salz?', '["Sie halten lange und sind leicht zu zählen.","Sie schmecken besser.","Sie sind leichter als Luft."]'::jsonb, 0, 'Salz kann nass werden und zerfallen. Münzen bleiben gleich und man kann sie abzählen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station3/q3')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Was kam in der Geschichte des Geldes zuerst?', '["Muscheln und andere seltene Dinge","Bezahlen mit dem Handy","Geldscheine"]'::jsonb, 0, 'Erst wurden seltene Dinge genutzt, dann Münzen, dann Scheine und heute auch digitales Geld.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station3/q4')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Warum wurden Geldscheine erfunden?', '["Große Beträge in Münzen sind schwer und unpraktisch.","Weil Münzen verboten wurden","Damit man Papier sparen kann"]'::jsonb, 0, 'Ein Schein kann viele Münzen ersetzen und passt in jede Tasche.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station3/q5')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Woher kommt das Geld, wenn du mit Karte oder Handy bezahlst?', '["Von einem Konto","Aus dem Handy-Akku","Aus der Kasse im Laden"]'::jsonb, 0, 'Beim digitalen Bezahlen wird Geld von einem Konto auf ein anderes übertragen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station3/q6')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Was ist bei allen Arten von Geld gleich geblieben?', '["Man kann damit bezahlen, weil alle es annehmen.","Es ist immer aus Gold.","Es ist immer rund."]'::jsonb, 0, 'Ob Muschel, Münze oder Karte: Geld funktioniert, weil alle es annehmen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station4')::uuid, md5('taleria:stage1/hafen')::uuid, 40, 'game', true, 100, '{"title":"Münzen und Scheine","number":4,"place":"Münzschublade im Hafenbüro","goal":"Euro-Münzen und Scheine kennen, Beträge mit Komma lesen und Wechselgeld berechnen","minutes":"7 bis 10 Min.","scene":[{"speaker":"tala","text":"In der Münzschublade herrscht Chaos! Alles liegt durcheinander."},{"speaker":"talo","text":"Dann sortieren wir. Kennst du alle Euro-Münzen und Scheine?"}],"lesson":[{"speaker":"talo","text":"Es gibt 8 Euro-Münzen: 1, 2, 5, 10, 20 und 50 Cent sowie 1 und 2 Euro.","image":"drawing:euro_coins"},{"speaker":"tala","text":"Und 100 Cent sind genau 1 Euro!","image":"drawing:cents_to_euro"},{"speaker":"talo","text":"Vor dem Komma stehen die Euro, dahinter die Cent. 2,05 € sind also 2 Euro und 5 Cent.","image":"drawing:comma_amount"},{"speaker":"talo","text":"Der kleinste Schein ist der 5-Euro-Schein. Für größere Beträge gibt es zum Beispiel Scheine für 10, 20 und 50 Euro.","image":"drawing:euro_notes"},{"speaker":"tala","text":"Mein Tipp: Wer einen Betrag mit möglichst wenigen Münzen legen will, nimmt zuerst die großen.","image":"drawing:big_coins_first"},{"speaker":"talo","text":"Geld gibt es übrigens auch digital auf einem Konto. Man sieht es nicht, aber es ist genauso viel wert.","image":"story.hafen.4.4"}],"game":{"type":"coins","title":"Münzschublade","description":"Münzen und Scheine sortieren, Beträge mit möglichst wenigen Münzen legen und Wechselgeld herausgeben.","task":"Tippe Münzen und Scheine an, bis der Betrag stimmt. Tippst du oben auf eine gelegte Münze, nimmst du sie wieder weg.","rounds":[{"question":"Lege 3,50 €. Schaffst du es mit möglichst wenigen Münzen?","amount":350},{"question":"Lege 1,85 € für eine Tüte Kirschen.","amount":185},{"question":"Ein Brötchen kostet 45 Cent. Tala bezahlt mit 1 €. Lege das Wechselgeld.","amount":55},{"question":"Eine Kinokarte kostet 7,50 €. Talo bezahlt mit einem 10-Euro-Schein. Lege das Wechselgeld.","amount":250}],"done":{"speaker":"tala","text":"Ich kenne jetzt alle Münzen und kann sogar Wechselgeld herausgeben!"},"beginner":{"type":"coins","title":"Münzschublade","description":"Münzen und Scheine sortieren, Beträge mit möglichst wenigen Münzen legen und Wechselgeld herausgeben.","task":"Tippe Münzen und Scheine an, bis der Betrag stimmt. Tippst du oben auf eine gelegte Münze, nimmst du sie wieder weg.","rounds":[{"question":"Lege 8 €. Schaffst du es mit möglichst wenigen Münzen und Scheinen?","amount":800},{"question":"Lege 80 Cent mit möglichst wenigen Münzen.","amount":80},{"question":"Ein Ball kostet 7 €. Tala bezahlt mit einem 10-Euro-Schein. Lege das Wechselgeld.","amount":300},{"question":"Eine Kinokarte kostet 9 €. Talo bezahlt mit einem 20-Euro-Schein. Lege das Wechselgeld.","amount":1100}],"done":{"speaker":"tala","text":"Ich kenne jetzt alle Münzen und kann sogar Wechselgeld herausgeben!"}}},"mini_game":{"type":"till","title":"Fischbrötchen-Kasse","description":"Am Fischbrötchen-Stand die Kasse übernehmen: Die Kunden bezahlen, und du gibst das richtige Wechselgeld heraus.","task":"Die Verkäuferin macht Pause, du übernimmst die Kasse! Lege das Wechselgeld mit Münzen und Scheinen und tippe dann auf „Herausgeben“.","image":"game.till","items":[{"text":"Fischbrötchen","price":350},{"text":"Brötchen","price":45},{"text":"Limo","price":180},{"text":"Apfelsaft","price":170}],"customers":[{"figure":"talo","text":"Ein Fischbrötchen, bitte!","price":350,"paid":500},{"figure":"haendler","name":"Händler","text":"Eine Limo für mich.","price":180,"paid":200},{"figure":"tala","text":"Ein Brötchen, bitte.","price":45,"paid":100},{"figure":"bootsbauer","name":"Bootsbauer","text":"Zwei Fischbrötchen für die Werkstatt.","price":700,"paid":1000},{"figure":"verkaeuferin","name":"Verkäuferin","text":"Pause muss sein: ein Fischbrötchen und einen Apfelsaft für mich!","price":520,"paid":1000},{"figure":"haendler","name":"Händler","text":"Drei Fischbrötchen für meine Mannschaft.","price":1050,"paid":2000}],"done":{"speaker":"verkaeuferin","text":"Danke für deine Hilfe! Jeder hat genau das richtige Wechselgeld bekommen.","name":"Verkäuferin"},"beginner":{"type":"till","title":"Fischbrötchen-Kasse","description":"Am Fischbrötchen-Stand die Kasse übernehmen: Die Kunden bezahlen, und du gibst das richtige Wechselgeld heraus.","task":"Die Verkäuferin macht Pause, du übernimmst die Kasse! Lege das Wechselgeld mit Münzen und Scheinen und tippe dann auf „Herausgeben“.","image":"game.till","items":[{"text":"Fischbrötchen","price":300},{"text":"Brötchen","price":100},{"text":"Limo","price":200},{"text":"Apfelsaft","price":200}],"customers":[{"figure":"talo","text":"Ein Fischbrötchen, bitte!","price":300,"paid":500},{"figure":"haendler","name":"Händler","text":"Eine Limo für mich.","price":200,"paid":500},{"figure":"tala","text":"Ein Brötchen, bitte.","price":100,"paid":200},{"figure":"bootsbauer","name":"Bootsbauer","text":"Zwei Fischbrötchen für die Werkstatt.","price":600,"paid":1000},{"figure":"verkaeuferin","name":"Verkäuferin","text":"Pause muss sein: ein Fischbrötchen und einen Apfelsaft für mich!","price":500,"paid":1000},{"figure":"haendler","name":"Händler","text":"Drei Fischbrötchen für meine Mannschaft.","price":900,"paid":2000}],"done":{"speaker":"verkaeuferin","text":"Danke für deine Hilfe! Jeder hat genau das richtige Wechselgeld bekommen.","name":"Verkäuferin"}}},"estimate":{"speaker":"tala","question":"Was glaubst du: Wie viele verschiedene Euro-Münzen gibt es?","kind":"wheel","min":1,"max":20,"start":5,"unit":"Münzen","unit_one":"Münze","answer":8,"reveal":{"speaker":"talo","text":"Es sind 8 Münzen: 1, 2, 5, 10, 20 und 50 Cent sowie 1 und 2 Euro."}},"taps":[{"after":1,"kind":"flip","text":"Dreh die Münze um und sieh dir die Rückseite an.","symbol":"muenze","back":"Auf der Rückseite hat jedes Land mit dem Euro sein eigenes Bild. Bezahlen kann man mit allen Euro-Münzen in allen diesen Ländern."},{"after":5,"kind":"drag","text":"Sortier die große Münze zuerst in die Schublade.","symbol":"muenze","done":"Erst die großen, dann die kleinen. So brauchst du weniger Münzen."}],"summary":{"speaker":"talo","text":"Jetzt kannst du Beträge mit Komma lesen, zusammenrechnen und Wechselgeld berechnen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station4/q1')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Wie schreibt man 2 Euro und 5 Cent richtig?', '["2,05 €","2,5 €","25 €"]'::jsonb, 0, 'Hinter dem Komma stehen immer zwei Stellen für die Cent: 5 Cent werden zu 05.', null, 'draft', '{"question":"Wie viele Cent sind 2 Euro?","answers":["200 Cent","20 Cent","2 Cent"],"correct_index":0,"explanation":"1 Euro sind 100 Cent, 2 Euro also 200 Cent."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station4/q2')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Was ist mehr: 1,50 € oder 105 Cent?', '["1,50 €","105 Cent","Beides gleich viel"]'::jsonb, 0, '1,50 € sind 150 Cent. Das ist mehr als 105 Cent.', null, 'draft', '{"question":"Was ist mehr: 2 € oder 150 Cent?","answers":["2 €","150 Cent","Beides gleich viel"],"correct_index":0,"explanation":"2 € sind 200 Cent. Das ist mehr als 150 Cent."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station4/q3')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Ein Heft kostet 1,30 €, ein Stift 0,90 €. Wie viel kostet beides zusammen?', '["2,20 €","2,10 €","1,20 €"]'::jsonb, 0, '1,30 € plus 0,90 € sind 2,20 €. Tipp: Rechne erst die Cent zusammen, 30 plus 90 sind 120 Cent.', null, 'draft', '{"question":"Ein Heft kostet 3 €, ein Stift 2 €. Wie viel kostet beides zusammen?","answers":["5 €","6 €","1 €"],"correct_index":0,"explanation":"3 € plus 2 € sind 5 €."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station4/q4')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Du zahlst mit einem 5-Euro-Schein für etwas, das 3,50 Euro kostet. Wie viel bekommst du zurück?', '["1,50 Euro","2,50 Euro","50 Cent"]'::jsonb, 0, '5 Euro minus 3,50 Euro sind 1,50 Euro.', null, 'draft', '{"question":"Du zahlst mit einem 10-Euro-Schein für etwas, das 7 Euro kostet. Wie viel bekommst du zurück?","answers":["3 Euro","4 Euro","17 Euro"],"correct_index":0,"explanation":"10 Euro minus 7 Euro sind 3 Euro."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station4/q5')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Drei Kugeln Eis kosten zusammen 4,50 €. Wie viel kostet eine Kugel?', '["1,50 €","1,20 €","1,80 €"]'::jsonb, 0, '4,50 € geteilt durch 3 sind 1,50 €, denn 3 mal 1,50 € sind 4,50 €.', null, 'draft', '{"question":"Drei Kugeln Eis kosten zusammen 6 €. Wie viel kostet eine Kugel?","answers":["2 €","3 €","18 €"],"correct_index":0,"explanation":"6 € geteilt durch 3 sind 2 €, denn 3 mal 2 € sind 6 €."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station4/q6')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Gibt es Geld auch, ohne dass man es anfassen kann?', '["Ja, auf einem Konto","Nein, Geld ist immer aus Metall oder Papier","Nur in Videospielen"]'::jsonb, 0, 'Auf einem Konto ist Geld gespeichert, ohne dass Münzen oder Scheine herumliegen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station5')::uuid, md5('taleria:stage1/hafen')::uuid, 50, 'game', true, 100, '{"title":"Woher kommt Geld?","number":5,"place":"Werft","goal":"Geld verdient man durch Arbeit","minutes":"6 bis 9 Min.","scene":[{"speaker":"bootsbauer","text":"Puh, heute haben wir das Boot vom Fischer repariert. Morgen ist Zahltag!","name":"Bootsbauer"},{"speaker":"tala","text":"Zahltag? Bekommt ihr Geld fürs Hämmern?"},{"speaker":"talo","text":"Sie bekommen Lohn, weil sie etwas leisten, das andere brauchen."}],"lesson":[{"speaker":"talo","text":"Die meisten Erwachsenen verdienen ihr Geld mit Arbeit. Dafür bekommen sie Lohn oder Gehalt.","image":"story.hafen.5.1"},{"speaker":"tala","text":"Die Bootsbauer reparieren Schiffe, der Bäcker backt Brot, die Ärztin hilft Kranken.","image":"story.hafen.5.2"},{"speaker":"talo","text":"Hergestellt wird Euro-Geld nur von bestimmten Stellen. Wer selbst Geld druckt, macht Falschgeld, und das ist verboten.","image":"story.hafen.5.3"},{"speaker":"tala","text":"Also: Geld drucken darf man nicht, Geld verdienen schon!"}],"game":{"type":"sort","title":"Berufe zuordnen","description":"Ordne jedem Beruf zu, was er für andere leistet.","task":"Tippe auf eine Karte und dann auf den passenden Beruf.","items":[{"text":"Backt frühmorgens frisches Brot","basket":0},{"text":"Backt einen Kuchen für ein Fest","basket":0},{"text":"Hilft, wenn jemand krank ist","basket":1},{"text":"Verbindet eine Wunde","basket":1},{"text":"Repariert das Fischerboot","basket":2},{"text":"Baut ein neues Ruderboot","basket":2},{"text":"Erklärt Rechnen und Lesen","basket":3},{"text":"Bereitet den Unterricht vor","basket":3}],"baskets":["Bäckerin","Ärztin","Bootsbauer","Lehrer"],"done":{"speaker":"talo","text":"Jeder leistet etwas, das andere brauchen. Dafür bekommen sie Lohn."}},"estimate":{"speaker":"tala","question":"Was glaubst du: Woher bekommen die Bootsbauer ihr Geld?","kind":"choice","options":["Sie drucken es selbst","Lohn für ihre Arbeit","Es wird ihnen geschenkt"],"answer":1,"reveal":{"speaker":"talo","text":"Sie bekommen Lohn für ihre Arbeit. Geld selbst drucken ist verboten."}},"taps":[{"after":1,"kind":"tap","text":"Hilf beim Reparieren: Tipp dreimal mit dem Hammer auf den Nagel.","symbol":"hammer","count":3,"done":"Fest! Das Boot ist repariert."},{"after":2,"kind":"drag","text":"Gib dem Bootsbauer seinen Lohnbeutel.","symbol":"beutel","done":"Lohn für gute Arbeit!"}],"summary":{"speaker":"talo","text":"Geld verdient man, indem man etwas leistet, das andere brauchen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station5/q1')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Wofür bekommt die Bäckerin Geld?', '["Für das Brot, das sie für andere backt","Fürs Ausschlafen","Weil sie eine Bäckermütze trägt"]'::jsonb, 0, 'Sie leistet etwas, das andere brauchen und wofür sie bezahlen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station5/q2')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Wie nennt man das Geld, das man für seine Arbeit bekommt?', '["Lohn oder Gehalt","Wechselgeld","Trinkgeld"]'::jsonb, 0, 'Für Arbeit gibt es Lohn oder Gehalt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station5/q3')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Wer darf Euro-Geldscheine herstellen?', '["Nur bestimmte Stellen, die dafür zuständig sind","Jeder mit einem guten Drucker","Jeder Laden"]'::jsonb, 0, 'Nur bestimmte Stellen dürfen Euro-Geld herstellen. Selbstgemachtes Geld ist Falschgeld.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station5/q4')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Warum bekommen die Bootsbauer Geld vom Fischer?', '["Weil sie sein Boot repariert haben","Weil sie Freunde sind","Weil Möwen zugeschaut haben"]'::jsonb, 0, 'Der Fischer bezahlt für eine Leistung, die er braucht.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station5/q5')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Was ist es, wenn jemand selbst Geldscheine druckt?', '["Falschgeld, und das ist verboten","Ein toller Trick, um reich zu werden","Erlaubt, wenn die Scheine hübsch sind"]'::jsonb, 0, 'Falschgeld schadet allen, deshalb ist es streng verboten.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station5/q6')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Welcher Satz stimmt?', '["Geld verdient man meistens durch Arbeit.","Geld wächst auf Bäumen.","Geld bekommt nur, wer laut fragt."]'::jsonb, 0, 'Für die meisten Menschen kommt das Geld aus ihrer Arbeit.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station6')::uuid, md5('taleria:stage1/hafen')::uuid, 60, 'game', true, 100, '{"title":"Warum kostet etwas etwas?","number":6,"place":"Fischbrötchen-Stand","goal":"Ein Preis besteht aus Kosten und Gewinn","minutes":"7 bis 10 Min.","scene":[{"speaker":"tala","text":"Was? So viel kostet ein Fischbrötchen? Der Fisch schwimmt doch einfach im Meer herum!"},{"speaker":"verkaeuferin","text":"Der Fisch muss gefangen werden, das Brötchen gebacken, und mein Stand kostet Miete.","name":"Verkäuferin"},{"speaker":"talo","text":"Lass uns den Preis mal auseinandernehmen."}],"lesson":[{"speaker":"talo","text":"Im Preis stecken die Zutaten: Fisch, Brötchen, Zwiebeln.","image":"story.hafen.6.1"},{"speaker":"talo","text":"Dazu kommen die Miete für den Stand und der Lohn für die Verkäuferin.","image":"story.hafen.6.2"},{"speaker":"tala","text":"Und was übrig bleibt, ist der Gewinn! Davon kann der Stand zum Beispiel einen neuen Grill kaufen.","image":"story.hafen.6.3"},{"speaker":"talo","text":"Ohne Gewinn lohnt sich der Stand nicht. Ist der Preis zu hoch, kaufen die Leute woanders.","image":"story.hafen.6.4"}],"game":{"type":"pick","title":"Preis-Säule","description":"Staple Zutaten, Miete, Lohn und Gewinn, bis die Säule genau den Preis ergibt.","task":"Ein Fischbrötchen kostet 10 Taler. Tippe die Teile an, aus denen der Preis besteht, bis die Säule genau 10 Taler hoch ist.","items":[{"text":"Fisch","price":4,"required":true},{"text":"Brötchen","price":1,"required":true},{"text":"Miete für den Stand","price":2,"required":true},{"text":"Lohn für die Verkäuferin","price":2,"required":true},{"text":"Kleiner Gewinn","price":1,"required":true},{"text":"Goldene Serviette","price":2,"required":false,"hint":"Eine goldene Serviette gibt es zum Fischbrötchen nicht. Die gehört nicht in den Preis."},{"text":"Talas Lieblingslied","price":1,"required":false,"hint":"Ein Lied kostet den Stand nichts. Das gehört nicht in den Preis."}],"target":10,"exact":true,"done":{"speaker":"verkaeuferin","text":"Genau so setzt sich mein Preis zusammen. Der kleine Gewinn ist mein Lohn fürs Kümmern.","name":"Verkäuferin"}},"estimate":{"speaker":"tala","question":"Was glaubst du: Wie viel vom Preis eines Fischbrötchens ist der Fisch?","kind":"choice","options":["Fast der ganze Preis","Ungefähr die Hälfte","Ungefähr ein Viertel"],"answer":2,"reveal":{"speaker":"verkaeuferin","text":"Ungefähr ein Viertel. Von 4 Euro ist etwa 1 Euro für den Fisch. Der Rest ist für Brötchen, Miete, Lohn und Gewinn."}},"taps":[{"after":1,"kind":"drag","text":"Leg den Fisch aufs Brötchen.","image":"item.fisch","done":"Lecker! Aber der Fisch ist nur ein Teil des Preises."},{"after":3,"kind":"flip","text":"Dreh das Preisschild um.","symbol":"preisschild","back":"Fisch, Brötchen, Miete, Lohn und Gewinn: Alles steckt im Preis."}],"summary":{"speaker":"tala","text":"Ein Preis besteht aus allen Kosten und einem kleinen Gewinn."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station6/q1')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Was gehört NICHT zu den Kosten eines Fischbrötchen-Stands?', '["Das Taschengeld der Kunden","Die Miete für den Stand","Der Fisch"]'::jsonb, 0, 'Kosten hat der Stand selbst: Zutaten, Miete, Lohn. Das Taschengeld der Kunden gehört nicht dazu.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station6/q2')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Ein Brötchen kostet den Bäcker 30 Cent. Er verkauft es für 40 Cent. Wie hoch ist sein Gewinn?', '["10 Cent","40 Cent","70 Cent"]'::jsonb, 0, '40 Cent minus 30 Cent Kosten sind 10 Cent Gewinn.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station6/q3')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Warum zahlt der Fischbrötchen-Stand Miete?', '["Weil er einen Platz nutzt, der jemand anderem gehört","Weil die Möwen es verlangen","Weil Miete lecker ist"]'::jsonb, 0, 'Wer einen Platz oder Raum nutzt, der jemand anderem gehört, zahlt dafür Miete.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station6/q4')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Was passiert, wenn ein Stand dauerhaft mehr ausgibt, als er einnimmt?', '["Er macht Verlust und muss bald schließen.","Er wird immer reicher.","Gar nichts"]'::jsonb, 0, 'Wer mehr ausgibt als einnimmt, macht Verlust. Das geht nicht lange gut.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station6/q5')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Wofür kann ein Stand seinen Gewinn nutzen?', '["Zum Beispiel für einen neuen Grill","Für gar nichts","Er muss ihn ins Meer werfen."]'::jsonb, 0, 'Mit dem Gewinn kann man Neues anschaffen, sparen oder davon leben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station6/q6')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Was passiert wahrscheinlich, wenn ein Stand viel zu viel für ein Fischbrötchen verlangt?', '["Viele Kunden kaufen woanders.","Es kommen noch mehr Kunden.","Die Fische springen freiwillig aufs Brötchen."]'::jsonb, 0, 'Ist ein Preis zu hoch, suchen sich die Kunden ein günstigeres Angebot.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station7')::uuid, md5('taleria:stage1/hafen')::uuid, 70, 'game', true, 100, '{"title":"Wie viel ist viel?","number":7,"place":"Marktplatz","goal":"Ein Gefühl für Preise bekommen","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Ich kaufe einfach alles! Das Eis, das Fahrrad und die Kinokarte!"},{"speaker":"talo","text":"Weißt du überhaupt, was das alles kostet?"},{"speaker":"tala","text":"Äh … nicht so genau."}],"lesson":[{"speaker":"talo","text":"Preise ungefähr zu kennen hilft. Dann merkst du, wenn etwas zu teuer ist.","image":"story.hafen.7.1"},{"speaker":"talo","text":"Ein Brötchen kostet viel weniger als eine Kinokarte. Und ein Fahrrad kostet ein Vielfaches davon.","image":"story.hafen.7.2"},{"speaker":"tala","text":"Ich schaue beim nächsten Einkauf mal ganz genau auf die Preisschilder!","image":"story.hafen.7.3"},{"speaker":"talo","text":"Gute Idee. Preise ändern sich mit der Zeit und sind nicht überall gleich. Deshalb lohnt sich Vergleichen.","image":"story.hafen.7.4"}],"game":{"type":"order","title":"Preise schätzen","description":"Schätze Preise von Alltagsdingen und sortiere sie von günstig bis teuer. Die Preise sind ungefähre Spannen.","task":"Tippe die Dinge der Reihe nach an: zuerst das günstigste.","items":[{"text":"Ein Brötchen","hint":"Etwa 40 Cent bis 1 Euro."},{"text":"Eine Kugel Eis","hint":"Etwa 1,50 bis 2,50 Euro."},{"text":"Eine Kinokarte","hint":"Etwa 8 bis 14 Euro."},{"text":"Ein Fußball","hint":"Etwa 15 bis 40 Euro."},{"text":"Ein Fahrrad","hint":"Etwa 250 bis 800 Euro."}],"from":"Günstig","to":"Teuer","done":{"speaker":"talo","text":"Gut geschätzt! Preise sind nicht überall gleich, aber ein Gefühl dafür hilft beim Einkaufen."},"beginner":{"type":"order","title":"Preise schätzen","description":"Schätze Preise von Alltagsdingen und sortiere sie von günstig bis teuer. Die Preise sind ungefähre Spannen.","task":"Tippe die Dinge der Reihe nach an: zuerst das günstigste.","items":[{"text":"Ein Brötchen","hint":"Etwa 40 Cent bis 1 Euro."},{"text":"Eine Kugel Eis","hint":"Etwa 2 Euro."},{"text":"Eine Kinokarte","hint":"Etwa 8 bis 14 Euro."},{"text":"Ein Fußball","hint":"Etwa 15 bis 40 Euro."},{"text":"Ein Fahrrad","hint":"Etwa 250 bis 800 Euro."}],"from":"Günstig","to":"Teuer","done":{"speaker":"talo","text":"Gut geschätzt! Preise sind nicht überall gleich, aber ein Gefühl dafür hilft beim Einkaufen."}}},"mini_game":{"type":"market","title":"Markt-Einkauf","description":"Mit 7,50 € alles auf der Einkaufsliste kaufen. Wer die Preise an den Ständen vergleicht, kommt mit dem Geld aus.","task":"Die Crew macht ein Picknick. Kaufe alles auf Talas Liste. Du hast 7,50 €. Vergleiche die Preise an den Ständen!","image":"game.market","images":{"Brötchen":"item.broetchen","Tüte Äpfel":"item.aepfel","Flasche Saft":"item.saft","Bonbons":"item.bonbons","Fischbrötchen":"item.fischbroetchen"},"budget":750,"needs":[{"item":"Brötchen","count":4},{"item":"Tüte Äpfel","count":1},{"item":"Flasche Saft","count":2}],"stands":[{"figure":"haendler","name":"Hafenladen","image":"game.stand.hafenladen","offers":[{"item":"Brötchen","price":70},{"item":"Tüte Äpfel","price":220},{"item":"Flasche Saft","price":150},{"item":"Bonbons","price":100}]},{"figure":"verkaeuferin","name":"Fischbrötchen-Stand","image":"game.stand.fischbroetchen","offers":[{"item":"Brötchen","price":50},{"item":"Flasche Saft","price":180},{"item":"Fischbrötchen","price":350}]},{"figure":"bootsbauer","name":"Obststand","image":"game.stand.obststand","offers":[{"item":"Tüte Äpfel","price":160},{"item":"Flasche Saft","price":190}]}],"done":{"speaker":"tala","text":"Alles gekauft, und es ist sogar Geld übrig! Vergleichen lohnt sich."},"beginner":{"type":"market","title":"Markt-Einkauf","description":"Mit 12 € alles auf der Einkaufsliste kaufen. Wer die Preise an den Ständen vergleicht, kommt mit dem Geld aus.","task":"Die Crew macht ein Picknick. Kaufe alles auf Talas Liste. Du hast 12 €. Vergleiche die Preise an den Ständen!","image":"game.market","images":{"Brötchen":"item.broetchen","Tüte Äpfel":"item.aepfel","Flasche Saft":"item.saft","Bonbons":"item.bonbons","Fischbrötchen":"item.fischbroetchen"},"budget":1200,"needs":[{"item":"Brötchen","count":4},{"item":"Tüte Äpfel","count":1},{"item":"Flasche Saft","count":2}],"stands":[{"figure":"haendler","name":"Hafenladen","image":"game.stand.hafenladen","offers":[{"item":"Brötchen","price":200},{"item":"Tüte Äpfel","price":300},{"item":"Flasche Saft","price":200},{"item":"Bonbons","price":100}]},{"figure":"verkaeuferin","name":"Fischbrötchen-Stand","image":"game.stand.fischbroetchen","offers":[{"item":"Brötchen","price":100},{"item":"Flasche Saft","price":300},{"item":"Fischbrötchen","price":300}]},{"figure":"bootsbauer","name":"Obststand","image":"game.stand.obststand","offers":[{"item":"Tüte Äpfel","price":200},{"item":"Flasche Saft","price":300}]}],"done":{"speaker":"tala","text":"Alles gekauft, und es ist sogar Geld übrig! Vergleichen lohnt sich."}}},"estimate":{"speaker":"talo","question":"Was glaubst du: Was kostet eine Kinokarte für Kinder?","kind":"slider","min":1,"max":20,"start":10,"unit":"Euro","reveal":{"speaker":"talo","text":"Für Kinder kostet eine Kinokarte meist zwischen 6 und 9 Euro, je nach Kino und Tag."}},"taps":[{"after":1,"kind":"drag","text":"Leg das Brötchen auf die Waage.","image":"item.broetchen","done":"Ein Brötchen ist leicht und kostet wenig."},{"after":3,"kind":"flip","text":"Dreh das Preisschild um.","symbol":"preisschild","back":"Preise ändern sich und sind nicht überall gleich. Vergleichen lohnt sich!"}],"summary":{"speaker":"tala","text":"Wer Preise ungefähr kennt, kann besser planen und lässt sich nicht so leicht übers Ohr hauen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station7/q1')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Was ist meistens am günstigsten?', '["Ein Brötchen","Eine Kinokarte","Ein Fahrrad"]'::jsonb, 0, 'Ein Brötchen kostet viel weniger als eine Kinokarte oder ein Fahrrad.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station7/q2')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Was ist meistens am teuersten?', '["Ein neues Handy","Eine Kugel Eis","Ein Brötchen"]'::jsonb, 0, 'Ein neues Handy kostet ein Vielfaches von Eis oder Brötchen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station7/q3')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Wie findest du heraus, wie viel etwas ungefähr kostet?', '["Preisschilder anschauen und vergleichen","Raten und nie nachsehen","Den Hund fragen"]'::jsonb, 0, 'Wer Preise vergleicht, bekommt ein gutes Gefühl dafür.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station7/q4')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Warum lohnt es sich, Preise ungefähr zu kennen?', '["Man merkt schneller, wenn etwas zu teuer ist.","Dann wird alles kostenlos.","Dann muss man nie wieder einkaufen."]'::jsonb, 0, 'Ein Gefühl für Preise schützt vor teuren Fehlern.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station7/q5')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Sind Preise überall und immer gleich?', '["Nein, sie können sich je nach Laden und Zeit unterscheiden.","Ja, überall genau gleich","Nur montags"]'::jsonb, 0, 'Preise ändern sich und sind nicht in jedem Laden gleich. Vergleichen lohnt sich.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station7/q6')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Tala will ein Eis, ein Fahrrad und eine Kinokarte auf einmal. Was sollte sie zuerst tun?', '["Herausfinden, was alles zusammen kostet","Alles sofort kaufen","Die Preisschilder abreißen"]'::jsonb, 0, 'Erst die Preise kennen, dann entscheiden, was drin ist.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station8')::uuid, md5('taleria:stage1/hafen')::uuid, 80, 'exam', true, 150, '{"title":"Abschlussprüfung","number":8,"place":"Hafenbüro","goal":"Alles vom Hafen wiederholen","minutes":"8 bis 10 Min.","scene":[{"speaker":"talo","text":"Zeit für die Abschlussprüfung! Ab 8 richtigen Antworten gehört das erste Kartenstück uns."},{"speaker":"tala","text":"Und wenn es nicht klappt, versuchen wir es einfach noch einmal. Ohne Strafe!"}],"summary":{"speaker":"tala","text":"Das erste Kartenstück! Auf zur Tauschinsel!"},"exam":{"show":10,"review":0,"pass":8}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q1')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum ist Geld praktischer als Tauschen?', '["Fast jeder nimmt es an.","Es ist leichter zu tragen als alles andere.","Es riecht besser."]'::jsonb, 0, 'Mit Geld muss man niemanden suchen, der genau das braucht, was man selbst hat.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q2')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was kann man mit Geld gut machen?', '["Es aufheben und später ausgeben","Es essen, wenn man Hunger hat","Es pflanzen, damit mehr wächst"]'::jsonb, 0, 'Geld kann man aufbewahren und später gegen etwas eintauschen.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q3')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum hat ein Geldschein einen Wert?', '["Weil alle ihn annehmen und darauf vertrauen","Weil er aus Gold ist","Weil er alt ist"]'::jsonb, 0, 'Der Wert entsteht, weil sich alle darauf verlassen.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q4')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Welche Schreibweise ist richtig für 4 Euro und 5 Cent?', '["4,05 €","4,5 €","45 €"]'::jsonb, 0, 'Die Cent stehen mit zwei Stellen hinter dem Komma: 4,05 €.', 4, 'draft', '{"question":"Wie viele Cent sind 4 Euro?","answers":["400 Cent","40 Cent","4 Cent"],"correct_index":0,"explanation":"1 Euro sind 100 Cent, 4 Euro also 400 Cent."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q5')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum haben sich Münzen gegenüber Muscheln und Salz durchgesetzt?', '["Sie halten lange und lassen sich leicht zählen.","Sie schmecken besser.","Sie leuchten im Dunkeln."]'::jsonb, 0, 'Münzen gehen nicht kaputt, sind gleich groß und man kann sie gut abzählen.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q6')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was ist ein Vorteil von Scheinen gegenüber vielen Münzen?', '["Große Beträge sind leichter zu tragen.","Sie klimpern lauter.","Sie sind aus Gold."]'::jsonb, 0, 'Ein Schein ersetzt viele Münzen und passt in jede Tasche.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q7')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Womit bezahlen viele Menschen heute oft, ohne Münzen oder Scheine?', '["Mit Karte oder Handy","Mit Muscheln","Mit Salz"]'::jsonb, 0, 'Heute wird viel digital bezahlt, das Geld kommt dann vom Konto.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q8')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Wie viele Cent sind 2,40 €?', '["240 Cent","24 Cent","2.040 Cent"]'::jsonb, 0, '2 Euro sind 200 Cent, dazu 40 Cent: zusammen 240 Cent.', 4, 'draft', '{"question":"Wie viele 1-Euro-Münzen sind so viel wert wie ein 5-Euro-Schein?","answers":["5","1","10"],"correct_index":0,"explanation":"Ein 5-Euro-Schein ist 5 Euro wert, also so viel wie fünf 1-Euro-Münzen."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q9')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Wie viele verschiedene Euro-Münzen gibt es?', '["8","5","12"]'::jsonb, 0, 'Es gibt 1, 2, 5, 10, 20 und 50 Cent sowie 1 und 2 Euro.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q10')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Ein Fahrradschloss kostet 12,60 €. Du zahlst mit einem 20-Euro-Schein. Wie viel bekommst du zurück?', '["7,40 €","8,40 €","7,60 €"]'::jsonb, 0, '20 € minus 12,60 € sind 7,40 €. Probe: 12,60 € plus 7,40 € sind 20 €.', 4, 'draft', '{"question":"Ein Fahrradschloss kostet 13 €. Du zahlst mit einem 20-Euro-Schein. Wie viel bekommst du zurück?","answers":["7 €","8 €","33 €"],"correct_index":0,"explanation":"20 € minus 13 € sind 7 €. Probe: 13 € plus 7 € sind 20 €."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q11')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Wie legst du 3,50 Euro mit möglichst wenigen Münzen?', '["2 Euro, 1 Euro und 50 Cent","Sieben 50-Cent-Münzen","Drei 1-Euro-Münzen und fünf 10-Cent-Münzen"]'::jsonb, 0, 'Große Münzen zuerst nehmen, dann braucht man am wenigsten.', 4, 'draft', '{"question":"Wie legst du 8 Euro mit möglichst wenigen Münzen und Scheinen?","answers":["Ein 5-Euro-Schein, 2 Euro und 1 Euro","Acht 1-Euro-Münzen","Vier 2-Euro-Münzen"],"correct_index":0,"explanation":"Große Scheine und Münzen zuerst nehmen, dann braucht man am wenigsten: 5 Euro plus 2 Euro plus 1 Euro."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q12')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Du bezahlst 2 Euro für etwas, das 1,20 Euro kostet. Wie viel Wechselgeld bekommst du?', '["80 Cent","1 Euro","20 Cent"]'::jsonb, 0, '2 Euro minus 1,20 Euro sind 80 Cent.', 4, 'draft', '{"question":"Du bezahlst mit einer 1-Euro-Münze für etwas, das 40 Cent kostet. Wie viel Wechselgeld bekommst du?","answers":["60 Cent","40 Cent","1 Euro"],"correct_index":0,"explanation":"1 Euro sind 100 Cent. 100 Cent minus 40 Cent sind 60 Cent."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q13')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Woher bekommen die meisten Erwachsenen ihr Geld?', '["Als Lohn für ihre Arbeit","Es wächst im Garten.","Sie finden es auf der Straße."]'::jsonb, 0, 'Wer arbeitet, bekommt dafür Lohn oder Gehalt.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q14')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum bekommen die Bootsbauer in der Werft Geld?', '["Weil sie für andere Schiffe reparieren","Weil sie lange schlafen","Weil sie Möwen füttern"]'::jsonb, 0, 'Geld bekommt man, weil man etwas leistet, das andere brauchen.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q15')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Darf man Euro-Geld einfach selbst drucken?', '["Nein, das ist verboten.","Ja, mit einem guten Drucker","Ja, aber nur am Wochenende"]'::jsonb, 0, 'Geld darf nur von bestimmten Stellen hergestellt werden, alles andere ist Falschgeld.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q16')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Woraus setzt sich der Preis eines Fischbrötchens zusammen?', '["Aus Zutaten, Miete, Lohn und Gewinn","Nur aus dem Fisch","Die Verkäuferin denkt sich einfach eine Zahl aus."]'::jsonb, 0, 'Ein Preis deckt alle Kosten und lässt einen kleinen Gewinn übrig.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q17')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was ist der Gewinn?', '["Das, was nach allen Kosten übrig bleibt","Das ganze Geld, das in die Kasse kommt","Das Trinkgeld"]'::jsonb, 0, 'Von den Einnahmen werden zuerst alle Kosten bezahlt, der Rest ist der Gewinn.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q18')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum ist ein Fischbrötchen am Hafen teurer als ein selbstgemachtes?', '["Weil Miete, Lohn und Gewinn dazukommen","Weil die Möwen mitessen","Weil Fisch am Hafen giftig ist"]'::jsonb, 0, 'Wer etwas verkauft, muss mehr verlangen als nur die Zutaten kosten.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q19')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was kostet normalerweise am meisten?', '["Ein Fahrrad","Eine Kugel Eis","Ein Brötchen"]'::jsonb, 0, 'Ein Fahrrad kostet ein Vielfaches von Eis oder Brötchen.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/hafen/station8/q20')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum hilft es, Preise ungefähr zu kennen?', '["Man merkt schneller, wenn etwas zu teuer ist.","Dann muss man nie wieder rechnen.","Dann wird alles billiger."]'::jsonb, 0, 'Wer Preise kennt, lässt sich nicht so leicht übers Ohr hauen.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

-- Ankerplatz 1: Das alte Handelsschiff
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/dive1')::uuid, md5('taleria:stage1/hafen')::uuid, 25, 'review_stop', true, 50, '{"title":"Das alte Handelsschiff","kind":"dive","number":1,"dive":{"game":"pearls","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Ein altes Handelsschiff! Überall liegen Waren, aber nirgends steht ein Preis."},{"speaker":"talo","text":"Im Logbuch steht: Am Ende wollte der Händler nur noch Münzen statt Tauschwaren. Warum wohl?"}],"question":"Warum wollte der Händler lieber Münzen als Tauschwaren?","answers":["Mit Münzen konnte er später bei jedem kaufen, was er brauchte.","Münzen glänzen schöner als Waren.","Tauschen war auf dem Meer verboten."],"correct_index":0,"explanation":"Geld nimmt fast jeder an. Der Händler musste niemanden mehr suchen, der genau seine Waren wollte."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/hafen/dive1/find')::uuid, 'hafen-fund-1', 'wreck_item', 'Alte Handelsmünze', 'collectible.hafen.1', md5('taleria:stage1/hafen/dive1')::uuid, 11, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 2: Die Münztruhe im Laderaum
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/dive2')::uuid, md5('taleria:stage1/hafen')::uuid, 45, 'review_stop', true, 50, '{"title":"Die Münztruhe im Laderaum","kind":"dive","number":2,"dive":{"game":"treasure_chest","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Eine Truhe voller Münzen! Wie viel ist das wohl in heutigem Geld?"},{"speaker":"talo","text":"Umgerechnet liegen darin zwei 1-Euro-Münzen, eine 50-Cent-Münze und drei 10-Cent-Münzen."}],"question":"Wie viel Geld ist in der Truhe?","answers":["2,80 Euro","2,53 Euro","5,30 Euro"],"correct_index":0,"explanation":"2 Euro plus 50 Cent plus 30 Cent sind 2,80 Euro. Mit heutigen Münzen geht das zum Beispiel so: eine 2-Euro-Münze, eine 50-Cent-Münze, eine 20-Cent-Münze und eine 10-Cent-Münze.","beginner":{"scene":[{"speaker":"tala","text":"Eine Truhe voller Münzen! Wie viel ist das wohl in heutigem Geld?"},{"speaker":"talo","text":"Umgerechnet liegen darin zwei 2-Euro-Münzen und drei 1-Euro-Münzen."}],"question":"Wie viel Geld ist in der Truhe?","answers":["7 Euro","5 Euro","4 Euro"],"correct_index":0,"explanation":"Zwei mal 2 Euro sind 4 Euro, dazu drei mal 1 Euro: zusammen 7 Euro."}}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/hafen/dive2/find')::uuid, 'hafen-fund-2', 'wreck_item', 'Kleine Münztruhe', 'collectible.hafen.2', md5('taleria:stage1/hafen/dive2')::uuid, 12, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 3: Der versunkene Fischbrötchen-Stand
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/dive3')::uuid, md5('taleria:stage1/hafen')::uuid, 65, 'review_stop', true, 50, '{"title":"Der versunkene Fischbrötchen-Stand","kind":"dive","number":3,"dive":{"game":"fish_swarm","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Hier unten liegt ein ganzer Fischbrötchen-Stand! Auf dem Schild steht: 4 Euro."},{"speaker":"talo","text":"Weißt du noch, was alles in so einem Preis steckt?"}],"question":"Wer hat an einem Fischbrötchen für 4 Euro mitverdient?","answers":["Der Fischer, der Bäcker, wer den Stand vermietet hat, und die Verkäuferin","Nur die Verkäuferin","Niemand, der Preis war ausgedacht"],"correct_index":0,"explanation":"Im Preis stecken Fisch, Brötchen, Miete und Lohn. Was übrig bleibt, ist der Gewinn."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/hafen/dive3/find')::uuid, 'hafen-fund-3', 'wreck_item', 'Rostiges Preisschild', 'collectible.hafen.3', md5('taleria:stage1/hafen/dive3')::uuid, 13, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

delete from public.quiz_questions q using public.stations s
where q.station_id = s.id and s.island_id = md5('taleria:stage1/hafen')::uuid
  and q.id not in (md5('taleria:stage1/hafen/station2/q1')::uuid, md5('taleria:stage1/hafen/station2/q2')::uuid, md5('taleria:stage1/hafen/station2/q3')::uuid, md5('taleria:stage1/hafen/station2/q4')::uuid, md5('taleria:stage1/hafen/station2/q5')::uuid, md5('taleria:stage1/hafen/station2/q6')::uuid, md5('taleria:stage1/hafen/station2/q7')::uuid, md5('taleria:stage1/hafen/station2/q8')::uuid, md5('taleria:stage1/hafen/station2/q9')::uuid, md5('taleria:stage1/hafen/station2/q10')::uuid, md5('taleria:stage1/hafen/station3/q1')::uuid, md5('taleria:stage1/hafen/station3/q2')::uuid, md5('taleria:stage1/hafen/station3/q3')::uuid, md5('taleria:stage1/hafen/station3/q4')::uuid, md5('taleria:stage1/hafen/station3/q5')::uuid, md5('taleria:stage1/hafen/station3/q6')::uuid, md5('taleria:stage1/hafen/station4/q1')::uuid, md5('taleria:stage1/hafen/station4/q2')::uuid, md5('taleria:stage1/hafen/station4/q3')::uuid, md5('taleria:stage1/hafen/station4/q4')::uuid, md5('taleria:stage1/hafen/station4/q5')::uuid, md5('taleria:stage1/hafen/station4/q6')::uuid, md5('taleria:stage1/hafen/station5/q1')::uuid, md5('taleria:stage1/hafen/station5/q2')::uuid, md5('taleria:stage1/hafen/station5/q3')::uuid, md5('taleria:stage1/hafen/station5/q4')::uuid, md5('taleria:stage1/hafen/station5/q5')::uuid, md5('taleria:stage1/hafen/station5/q6')::uuid, md5('taleria:stage1/hafen/station6/q1')::uuid, md5('taleria:stage1/hafen/station6/q2')::uuid, md5('taleria:stage1/hafen/station6/q3')::uuid, md5('taleria:stage1/hafen/station6/q4')::uuid, md5('taleria:stage1/hafen/station6/q5')::uuid, md5('taleria:stage1/hafen/station6/q6')::uuid, md5('taleria:stage1/hafen/station7/q1')::uuid, md5('taleria:stage1/hafen/station7/q2')::uuid, md5('taleria:stage1/hafen/station7/q3')::uuid, md5('taleria:stage1/hafen/station7/q4')::uuid, md5('taleria:stage1/hafen/station7/q5')::uuid, md5('taleria:stage1/hafen/station7/q6')::uuid, md5('taleria:stage1/hafen/station8/q1')::uuid, md5('taleria:stage1/hafen/station8/q2')::uuid, md5('taleria:stage1/hafen/station8/q3')::uuid, md5('taleria:stage1/hafen/station8/q4')::uuid, md5('taleria:stage1/hafen/station8/q5')::uuid, md5('taleria:stage1/hafen/station8/q6')::uuid, md5('taleria:stage1/hafen/station8/q7')::uuid, md5('taleria:stage1/hafen/station8/q8')::uuid, md5('taleria:stage1/hafen/station8/q9')::uuid, md5('taleria:stage1/hafen/station8/q10')::uuid, md5('taleria:stage1/hafen/station8/q11')::uuid, md5('taleria:stage1/hafen/station8/q12')::uuid, md5('taleria:stage1/hafen/station8/q13')::uuid, md5('taleria:stage1/hafen/station8/q14')::uuid, md5('taleria:stage1/hafen/station8/q15')::uuid, md5('taleria:stage1/hafen/station8/q16')::uuid, md5('taleria:stage1/hafen/station8/q17')::uuid, md5('taleria:stage1/hafen/station8/q18')::uuid, md5('taleria:stage1/hafen/station8/q19')::uuid, md5('taleria:stage1/hafen/station8/q20')::uuid);

insert into public.badges (id, slug, kind, island_id, title, asset_key, sort_order, status)
values (md5('taleria:stage1/hafen/badge')::uuid, 'hafen', 'island', md5('taleria:stage1/hafen')::uuid, 'Erster Landgang', 'badge.hafen', 1, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, sort_order = excluded.sort_order,
  status = excluded.status;

insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/hafen/prompt1')::uuid, md5('taleria:stage1/hafen')::uuid, 'Was war das Erste, das du dir von deinem eigenen Geld gekauft hast? (Eltern erzählen)', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/hafen/prompt2')::uuid, md5('taleria:stage1/hafen')::uuid, 'Was glaubst du, wie viel unser Wocheneinkauf kostet?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/hafen/prompt3')::uuid, md5('taleria:stage1/hafen')::uuid, 'Womit haben wir bezahlt, als ich so alt war wie du?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/hafen')::uuid and status <> 'draft';

-- 2. Tauschinsel, Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/tauschinsel')::uuid, 'tauschinsel', 1, 1, 2, 0.28, 0.9, 'main', 'Tauschinsel', '{"goal":"Das Kind erlebt, wie Tauschen ohne Geld funktioniert, versteht, dass Wert von Person und Situation abhängt, wie Angebot und Nachfrage Preise beeinflussen, dass billig nicht immer günstig ist, dass jede Entscheidung einen Verzicht bedeutet und was ein fairer Tausch ist.","learn":["Wie Tauschen ohne Geld klappt und wann nicht","Warum etwas für jeden anders viel wert ist","Warum billig nicht immer günstig ist"],"access":"free","arrival":{"video_key":"video.arrival.tauschinsel","scene":[{"speaker":"talo","text":"Land in Sicht! Und unser Proviant ist fast leer."},{"speaker":"tala","text":"Drei Äpfel, bitte! Ich habe Taler!"},{"speaker":"bruno","text":"Taler? Was soll ich damit? Hier wird getauscht!","name":"Bruno"},{"speaker":"talo","text":"Dann müssen wir wohl lernen zu tauschen."},{"speaker":"olga","text":"Dieses Kartenstück bekommt nur, wer fair tauscht.","name":"Olga"}]},"badge":"Meistertauscher","real_life_task":{"title":"Fairer Tausch","text":"Tausche mit jemandem aus der Familie etwas (Buch, Spielzeug, Sammelkarte). Erzählt euch vorher gegenseitig, warum euch die Sachen etwas wert sind, und klärt, ob man zurücktauschen darf."},"teaser":{"scene":[{"speaker":"tala","text":"Da vorn glitzert etwas! Eine ganze Insel voller schöner Dinge."},{"speaker":"talo","text":"Die Wunschinsel. Mal sehen, ob du dort einen kühlen Kopf behältst, Tala."}],"next_slug":"wunschinsel","next_title":"Wunschinsel"}}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Stopp auf See 1: Das Händlerschiff
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/sea1')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 1, 'sea_stop', true, 30, '{"title":"Das Händlerschiff","kind":"sea_stop","stop":{"type":"haendlerschiff","figure":"haendler","index":1,"ship":"ship.haendler"},"scene":[{"speaker":"haendler","text":"Ahoi, Crew! Ich segle mit meinem Händlerschiff auch zur Tauschinsel. Was habt ihr im Hafen gelernt?"},{"speaker":"talo","text":"Eine ganze Menge! Frag ruhig."},{"speaker":"haendler","text":"Dann beantwortet mir drei Fragen, und wir segeln zusammen weiter."}],"summary":{"speaker":"haendler","text":"Sehr gut, ihr kennt euch mit Geld aus! Gute Fahrt zur Tauschinsel."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea1/q1')::uuid, md5('taleria:stage1/tauschinsel/sea1')::uuid, 'Warum nehmen Händler lieber Geld als Waren zum Tauschen?', '["Fast jeder nimmt Geld an.","Weil Waren nichts wert sind.","Weil Geld nie an Wert verliert."]'::jsonb, 0, 'Beim Tauschen muss jeder genau das haben, was der andere braucht. Geld nimmt fast jeder an.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea1/q2')::uuid, md5('taleria:stage1/tauschinsel/sea1')::uuid, 'Warum hat man früher oft mit Muscheln oder Salz bezahlt?', '["Weil sie selten waren und viele sie haben wollten","Weil sie besonders schwer waren","Weil Tauschen damals verboten war"]'::jsonb, 0, 'Bezahlt wurde mit Dingen, die knapp und begehrt waren. Nur dann nimmt sie jeder gern an.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea1/q3')::uuid, md5('taleria:stage1/tauschinsel/sea1')::uuid, 'Warum kann man Geld gut aufheben?', '["Es wird nicht schlecht.","Es wird jedes Jahr mehr.","Man muss es jeden Tag ausgeben."]'::jsonb, 0, 'Ein Fischbrötchen wird schlecht, ein Taler nicht. Deshalb kann man Geld für später aufheben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea1/q4')::uuid, md5('taleria:stage1/tauschinsel/sea1')::uuid, 'Wie verdienen die meisten Erwachsenen ihr Geld?', '["Mit Arbeit, dafür bekommen sie Lohn oder Gehalt","Sie bekommen es von der Bank geschenkt.","Jeder Erwachsene bekommt vom Staat gleich viel."]'::jsonb, 0, 'Die meisten Erwachsenen arbeiten und bekommen dafür Lohn oder Gehalt. Geld selbst drucken ist verboten.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea1/q5')::uuid, md5('taleria:stage1/tauschinsel/sea1')::uuid, 'Was steckt alles im Preis eines Fischbrötchens?', '["Zutaten, Miete, Lohn und ein Gewinn","Nur der Fisch","Nur der Gewinn des Stands"]'::jsonb, 0, 'Im Preis stecken die Zutaten, die Miete für den Stand, der Lohn der Verkäuferin und ein Gewinn.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea1/q6')::uuid, md5('taleria:stage1/tauschinsel/sea1')::uuid, 'Was passiert, wenn ein Stand viel zu hohe Preise verlangt?', '["Die Leute kaufen woanders.","Der Stand verdient automatisch mehr.","Die anderen Stände werden auch teurer."]'::jsonb, 0, 'Ist der Preis zu hoch, kaufen die Leute woanders. Deshalb muss ein Preis passen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;

-- Stopp auf See 2: Das Fischerboot
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/sea2')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 2, 'sea_stop', true, 30, '{"title":"Das Fischerboot","kind":"sea_stop","stop":{"type":"fischerboot","figure":"otti","index":2,"ship":"ship.fischer"},"scene":[{"speaker":"otti","text":"Hilfe! Ich verkaufe Fische und komme mit dem Wechselgeld durcheinander."},{"speaker":"tala","text":"Wir helfen dir! Rechnen mit Münzen haben wir im Hafen geübt."},{"speaker":"otti","text":"Danke! Dann los, die Kundschaft wartet."}],"summary":{"speaker":"otti","text":"Jetzt stimmt meine Kasse! Wir sehen uns auf der Tauschinsel."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea2/q1')::uuid, md5('taleria:stage1/tauschinsel/sea2')::uuid, 'Ein Fisch kostet 2,50 €. Wie viel kosten 3 Fische?', '["7,50 €","6,50 €","7 €"]'::jsonb, 0, '3 mal 2 € sind 6 €, dazu 3 mal 50 Cent, also 1,50 €: zusammen 7,50 €.', null, 'draft', '{"question":"Ein Fisch kostet 3 €. Wie viel kosten 4 Fische?","answers":["12 €","7 €","10 €"],"correct_index":0,"explanation":"4 mal 3 € sind 12 €."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea2/q2')::uuid, md5('taleria:stage1/tauschinsel/sea2')::uuid, 'Wie viele Cent sind 3,05 €?', '["305 Cent","35 Cent","350 Cent"]'::jsonb, 0, '3 Euro sind 300 Cent, dazu 5 Cent: zusammen 305 Cent.', null, 'draft', '{"question":"Wie viele 50-Cent-Münzen sind zusammen 2 Euro?","answers":["4","2","20"],"correct_index":0,"explanation":"Zwei 50-Cent-Münzen sind 1 Euro. Für 2 Euro braucht man also vier."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea2/q3')::uuid, md5('taleria:stage1/tauschinsel/sea2')::uuid, 'Ein Fisch kostet 3,40 €. Jemand zahlt mit einem 5-Euro-Schein. Wie viel Wechselgeld bekommt er?', '["1,60 €","2,60 €","1,40 €"]'::jsonb, 0, '5 € minus 3,40 € sind 1,60 €. Probe: 3,40 € plus 1,60 € sind 5 €.', null, 'draft', '{"question":"Ein Fisch kostet 6 €. Jemand zahlt mit einem 10-Euro-Schein. Wie viel Wechselgeld bekommt er?","answers":["4 €","3 €","16 €"],"correct_index":0,"explanation":"10 € minus 6 € sind 4 €. Probe: 6 € plus 4 € sind 10 €."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea2/q4')::uuid, md5('taleria:stage1/tauschinsel/sea2')::uuid, 'Welche Münzen ergeben zusammen genau 1,70 €?', '["1 Euro, 50 Cent und 20 Cent","1 Euro und 50 Cent","Zwei 50-Cent-Münzen und 20 Cent"]'::jsonb, 0, '1 Euro plus 50 Cent plus 20 Cent sind 1,70 €.', null, 'draft', '{"question":"Welche Münzen ergeben zusammen genau 5 €?","answers":["2 Euro, 2 Euro und 1 Euro","2 Euro und 2 Euro","Zwei 1-Euro-Münzen und 2 Euro"],"correct_index":0,"explanation":"2 Euro plus 2 Euro plus 1 Euro sind 5 €."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea2/q5')::uuid, md5('taleria:stage1/tauschinsel/sea2')::uuid, 'Was ist mehr wert: ein 5-Euro-Schein oder acht 50-Cent-Münzen?', '["Der 5-Euro-Schein","Die acht 50-Cent-Münzen","Beides gleich viel"]'::jsonb, 0, 'Acht mal 50 Cent sind 4 €. Das ist weniger als 5 €.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/sea2/q6')::uuid, md5('taleria:stage1/tauschinsel/sea2')::uuid, 'Otti verkauft 4 Fische für zusammen 10 €. Wie viel kostet ein Fisch?', '["2,50 €","2,40 €","4 €"]'::jsonb, 0, '10 € geteilt durch 4 sind 2,50 €. Probe: 4 mal 2,50 € sind 10 €.', null, 'draft', '{"question":"Otti verkauft 4 Fische für zusammen 12 €. Wie viel kostet ein Fisch?","answers":["3 €","4 €","8 €"],"correct_index":0,"explanation":"12 € geteilt durch 4 sind 3 €. Probe: 4 mal 3 € sind 12 €."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station1')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 10, 'game', true, 100, '{"title":"Hier gibt es kein Geld","number":1,"place":"Anlegestelle","goal":"Tauschen klappt nur, wenn beide genau das wollen, was der andere hat","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Ich brauche ein neues Seil fürs Schiff. Ich bezahle mit Talern!"},{"speaker":"greta","text":"Taler? Hier wird getauscht. Für mein Seil will ich Äpfel.","name":"Greta"},{"speaker":"tala","text":"Äpfel hab ich keine …"},{"speaker":"talo","text":"Dann fragen wir herum, wer was braucht."}],"lesson":[{"speaker":"bruno","text":"Äpfel gebe ich gern her. Aber nur gegen Fisch!","name":"Bruno","image":"story.tauschinsel.1.1"},{"speaker":"otti","text":"Fisch habe ich. Ich hätte gern einen Eimer.","name":"Otti","image":"story.tauschinsel.1.2"},{"speaker":"tala","text":"Einen Eimer haben wir an Bord!","image":"story.tauschinsel.1.3"},{"speaker":"talo","text":"Also: Eimer gegen Fisch, Fisch gegen Äpfel, Äpfel gegen Seil. Das nennt man eine Tauschkette.","image":"story.tauschinsel.1.4"},{"speaker":"tala","text":"Ganz schön viel Lauferei für ein Seil!"}],"game":{"type":"choice","title":"Wer will was?","description":"Baue die Tauschkette: Eimer gegen Fisch, Fisch gegen Äpfel, Äpfel gegen Seil.","task":"Tala braucht ein Seil. Auf der Tafel siehst du, wer was hat und was will. Baue mit ihr die Tauschkette.","rounds":[{"scene":[{"speaker":"greta","text":"Mein Seil? Gern, aber nur gegen Äpfel.","name":"Greta"},{"speaker":"tala","text":"Äpfel hab ich nicht. Ich hab nur einen Eimer."}],"question":"Wer hat Äpfel?","options":[{"text":"Bruno","good":true,"reply":"Richtig, Bruno hat Äpfel. Aber was will er dafür?"},{"text":"Otti","good":false,"reply":"Otti ist Fischerin. Sie hat Fisch, aber keine Äpfel."}]},{"scene":[{"speaker":"bruno","text":"Äpfel gebe ich nur gegen frischen Fisch.","name":"Bruno"}],"question":"Wo bekommt Tala Fisch?","options":[{"text":"Bei Otti, sie braucht einen Eimer","good":true,"reply":"Super! Otti will einen Eimer, und den hat Tala."},{"text":"Bei Greta","good":false,"reply":"Greta hat ein Seil, aber keinen Fisch."}]},{"scene":[{"speaker":"talo","text":"Jetzt haben wir alles zusammen. In welcher Reihenfolge tauschen wir?"}],"question":"Wie geht die Tauschkette?","options":[{"text":"Eimer → Fisch → Äpfel → Seil","good":true,"reply":"Genau so! Otti bekommt den Eimer, Bruno den Fisch, Greta die Äpfel. Und Tala hat ihr Seil."},{"text":"Eimer → Seil","good":false,"reply":"Greta will keinen Eimer, nur Äpfel."},{"text":"Äpfel → Eimer → Seil","good":false,"reply":"Am Anfang hat Tala gar keine Äpfel, nur den Eimer."}]}],"traders":[{"figure":"greta","name":"Greta","has":"Seil","wants":"Äpfel"},{"figure":"bruno","name":"Bruno","has":"Äpfel","wants":"Fisch"},{"figure":"otti","name":"Otti","has":"Fisch","wants":"Eimer"}],"images":{"Eimer":"item.eimer","Fisch":"item.fisch","Äpfel":"item.aepfel","Seil":"item.seil"},"done":{"speaker":"tala","text":"Drei Tausche für ein Seil! Mit Geld wäre das schneller gegangen."}},"mini_game":{"type":"trade_chain","title":"Tauschkette","description":"Tala hat nur einen Eimer, braucht aber ein Seil. Wer will was? Plane die Tauschkette.","task":"Tala braucht ein Seil für das Schiff, hat aber nur einen Eimer. Tippe einen Händler an, um zu tauschen. Schau vorher genau, wer was will!","image":"story.tauschinsel.1.4","images":{"Eimer":"item.eimer","Fisch":"item.fisch","Äpfel":"item.aepfel","Seil":"item.seil","Muschel":"item.muschel"},"start":"Eimer","goal":"Seil","traders":[{"figure":"greta","name":"Greta","has":"Seil","wants":"Äpfel"},{"figure":"olga","name":"Olga","has":"Muschel","wants":"Eimer"},{"figure":"bruno","name":"Bruno","has":"Äpfel","wants":"Fisch"},{"figure":"otti","name":"Otti","has":"Fisch","wants":"Eimer"}],"dead_end":{"speaker":"tala","text":"Oh nein, die Muschel will hier niemand. Lass uns von vorn anfangen!"},"done":{"speaker":"tala","text":"Drei Tausche für ein Seil! Mit Geld wäre das schneller gegangen."}},"estimate":{"speaker":"tala","question":"Was glaubst du: Wie viele Tausche brauche ich, bis ich das Seil habe?","kind":"wheel","min":1,"max":10,"start":1,"unit":"Tausche","unit_one":"Tausch","answer":3,"reveal":{"speaker":"talo","text":"Drei Tausche: Eimer gegen Fisch, Fisch gegen Äpfel und Äpfel gegen das Seil."}},"taps":[{"after":3,"kind":"drag","text":"Bring den Eimer zu Otti.","image":"item.eimer","done":"Otti gibt dir dafür einen Fisch."},{"after":4,"kind":"drag","text":"Bring den Fisch zu Bruno.","image":"item.fisch","done":"Bruno gibt dir dafür Äpfel."}],"summary":{"speaker":"talo","text":"Tauschen klappt nur, wenn beide genau das wollen, was der andere hat. Sonst braucht man eine lange Tauschkette."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station1/q1')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Warum braucht Tala auf der Tauschinsel eine Tauschkette?', '["Weil Greta etwas will, das Tala nicht direkt hat","Weil Tauschen schneller geht als Bezahlen","Weil Greta nur Taler annimmt"]'::jsonb, 0, 'Will der andere nicht, was man hat, muss man über mehrere Tausche gehen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station1/q2')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Was ist der erste Tausch in Talas Kette?', '["Eimer gegen Fisch","Seil gegen Äpfel","Taler gegen Seil"]'::jsonb, 0, 'Otti will den Eimer und gibt dafür Fisch. Damit beginnt die Kette.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station1/q3')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Warum sind Talas Taler auf der Tauschinsel nichts wert?', '["Weil dort niemand Taler annimmt","Weil Talas Taler gefälscht sind","Weil man dort mit Euro bezahlt"]'::jsonb, 0, 'Geld hat nur einen Wert, wenn andere es annehmen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station1/q4')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Was ist beim Tauschen ohne Geld oft das größte Problem?', '["Man muss jemanden finden, der genau das will, was man hat.","Man bekommt immer weniger zurück, als man gibt.","Man braucht dafür immer einen Händler."]'::jsonb, 0, 'Beide Seiten müssen zueinander passen. Das ist selten.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station1/q5')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Wie viele Tausche braucht Tala für das Seil?', '["Drei","Einen","Zwei"]'::jsonb, 0, 'Eimer gegen Fisch, Fisch gegen Äpfel, Äpfel gegen Seil: drei Tausche.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station1/q6')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Wie wäre es mit Geld einfacher?', '["Tala könnte Greta direkt bezahlen.","Greta würde dann gar nichts mehr verkaufen.","Tala müsste trotzdem erst Fisch besorgen."]'::jsonb, 0, 'Mit Geld braucht man keine Tauschkette, weil fast jeder Geld annimmt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station2')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 20, 'game', true, 100, '{"title":"Das große Tauschspiel","number":2,"place":"Tauschmarkt","goal":"Vor einem Tausch überlegen: Was brauche ich, was gebe ich her?","minutes":"7 bis 10 Min.","scene":[{"speaker":"talo","text":"Heute Nacht wollen wir weitersegeln. Dafür brauchen wir eine Laterne."},{"speaker":"tala","text":"Ich habe eine Muschelkette, einen Korb und ein Stück Käse."},{"speaker":"bruno","text":"Eine Laterne findest du hier auf dem Markt. Aber nicht jeder tauscht gegen alles!","name":"Bruno"}],"lesson":[{"speaker":"talo","text":"Bevor du tauschst, frag dich: Was brauche ich wirklich? Und was gebe ich dafür her?","image":"story.tauschinsel.2.1"},{"speaker":"tala","text":"Manche Angebote klingen gut, sind es aber nicht. Drei Äpfel für meine schöne Kette? Nein danke!","image":"story.tauschinsel.2.2"},{"speaker":"talo","text":"Ein guter Tausch macht beide zufrieden. Und manchmal sagt man besser Nein.","image":"story.tauschinsel.2.3"}],"game":{"type":"choice","title":"Tauschmarkt","description":"Starte mit drei Dingen und ertausche in mehreren Runden eine Laterne. Jeder Händler will etwas anderes, manche Angebote sind schlecht.","task":"Du startest mit Muscheln, einer Mütze und einer Flöte. Ertausche eine Laterne für die Nachtfahrt.","rounds":[{"scene":[{"speaker":"haendler","text":"Laternen gibt es bei mir nur gegen Kerzen.","name":"Laternen-Händler"}],"question":"Was brauchst du also zuerst?","options":[{"text":"Kerzen","good":true,"reply":"Genau. Erst Kerzen besorgen, dann bekommst du die Laterne."},{"text":"Mehr Muscheln","good":false,"reply":"Der Händler will Kerzen. Mehr Muscheln helfen dir nicht."}]},{"scene":[{"speaker":"bruno","text":"Drei Äpfel für deine Flöte, deine Mütze und alle deine Muscheln!","name":"Bruno"}],"question":"Nimmst du das Angebot an?","options":[{"text":"Nein, das ist viel zu viel für drei Äpfel","good":true,"reply":"Gut aufgepasst! Du würdest alles hergeben und Äpfel brauchst du gar nicht."},{"text":"Ja, sofort","good":false,"reply":"Dann hast du nichts mehr und immer noch keine Kerzen. Vor einem Tausch lohnt es sich zu überlegen."}]},{"scene":[{"speaker":"greta","text":"Ich hätte Kerzen. Mir ist kalt, eine Mütze wäre schön.","name":"Greta"}],"question":"Was gibst du Greta?","options":[{"text":"Die Mütze","good":true,"reply":"Fair für beide: Greta bekommt ihre Mütze, du die Kerzen. Die Mütze brauchst du gerade nicht."},{"text":"Die Flöte","good":false,"reply":"Greta will etwas gegen die Kälte. Mit einer Flöte kann sie nichts anfangen."}]},{"scene":[{"speaker":"haendler","text":"Kerzen! Wunderbar, die Laterne gehört dir.","name":"Laternen-Händler"}],"question":"Was hast du beim Tauschmarkt gelernt?","options":[{"text":"Erst überlegen: Was brauche ich, was gebe ich her?","good":true,"reply":"Genau so. Und schlechte Angebote darf man ablehnen."},{"text":"Immer das erste Angebot nehmen","good":false,"reply":"Dann hättest du bei Bruno alles für drei Äpfel hergegeben."}]}],"done":{"speaker":"talo","text":"Die Laterne leuchtet! Gut überlegt getauscht."}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie viele Händler muss Tala fragen, bis sie die Laterne hat?","kind":"wheel","min":1,"max":10,"start":3,"unit":"Händler","answer":2,"reveal":{"speaker":"tala","text":"Zwei! Der Dachs wollte meine Kette für drei schrumpelige Äpfel. Die Ente hat mir die Laterne für meinen Korb gegeben."}},"taps":[{"after":1,"kind":"tap","text":"Öffne Talas Rucksack.","symbol":"rucksack","done":"Darin: eine Muschelkette, ein Korb und ein Stück Käse."},{"after":2,"kind":"drag","text":"Leg den Korb auf den Tauschtisch.","symbol":"beutel","done":"Die Ente schaut sich den Korb genau an."}],"summary":{"speaker":"tala","text":"Vor jedem Tausch nachdenken lohnt sich: Was brauche ich, und was gebe ich dafür her?"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station2/q1')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Was solltest du vor einem Tausch klären?', '["Was ich brauche und was ich dafür hergebe","Ob der andere nett aussieht","Wer zuerst etwas anbietet"]'::jsonb, 0, 'Wer weiß, was er will, tauscht klüger.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station2/q2')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Ein Händler bietet dir eine kaputte Laterne gegen deinen besten Korb. Was tust du?', '["Ablehnen oder nachverhandeln","Sofort tauschen, damit er nicht beleidigt ist","Den Korb tauschen und hoffen, dass die Laterne noch geht"]'::jsonb, 0, 'Man muss nicht jedes Angebot annehmen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station2/q3')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Woran erkennst du einen guten Tausch?', '["Beide sind am Ende zufrieden.","Einer hat den anderen ausgetrickst.","Es ging besonders schnell."]'::jsonb, 0, 'Ein guter Tausch ist für beide fair.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station2/q4')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Ein Händler drängt: „Tausch sofort, sonst ist mein Angebot weg!“ Was ist klug?', '["In Ruhe überlegen, ob sich der Tausch lohnt","Sofort tauschen, bevor es zu spät ist","Noch etwas drauflegen, damit er wartet"]'::jsonb, 0, 'Wer drängelt, will oft verhindern, dass du nachdenkst. Ein guter Tausch ist auch in fünf Minuten noch gut.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station2/q5')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Tala braucht eine Laterne. Welches Angebot hilft ihr am meisten?', '["Eine Laterne gegen ihren Korb","Drei Äpfel gegen ihre Kette","Ein Hut gegen ihren Käse"]'::jsonb, 0, 'Ein Tausch hilft, wenn man bekommt, was man wirklich braucht.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station2/q6')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Wann ist ein Tausch schlecht für dich?', '["Wenn du viel mehr hergibst, als du bekommst","Immer, Tauschen ist schlecht","Wenn der andere auch zufrieden ist"]'::jsonb, 0, 'Gibt man viel ab und bekommt wenig, lohnt sich der Tausch nicht.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station3')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 30, 'game', true, 100, '{"title":"Wert ist nicht für jeden gleich","number":3,"place":"Quelle am Berg","goal":"Wert hängt von Person und Situation ab","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Puh, dieser Aufstieg! Ich habe so einen Durst!"},{"speaker":"talo","text":"Unten am Strand gab es überall Wasser. Hier oben wäre eine Flasche Wasser ein Schatz."},{"speaker":"tala","text":"Ich würde jetzt sogar mein Lieblings-Fischbrötchen gegen Wasser tauschen!"},{"speaker":"talo","text":"Ich mag Fischbrötchen gar nicht. Für mich wäre das kein guter Tausch."}],"lesson":[{"speaker":"talo","text":"Wie viel etwas wert ist, hängt von der Situation ab. Wasser ist oben am Berg in der Hitze mehr wert als unten an der Quelle.","image":"story.tauschinsel.3.1"},{"speaker":"tala","text":"Und es hängt von der Person ab: Ich liebe Fischbrötchen, Talo nicht.","image":"story.tauschinsel.3.2"},{"speaker":"talo","text":"Deshalb kann ein Tausch für beide gut sein: Jeder bekommt das, was ihm mehr wert ist.","image":"story.tauschinsel.3.3"}],"game":{"type":"choice","title":"Was ist wem wie viel wert?","description":"Entscheide in verschiedenen Situationen, wem etwas wie viel wert ist.","task":"Entscheide in jeder Situation, wem etwas wie viel wert ist.","rounds":[{"scene":[{"speaker":"tala","text":"Hier unten am Strand gibt es überall Wasser. Jemand will 5 Taler für eine Flasche."}],"question":"Ist die Flasche hier viel wert?","options":[{"text":"Nein, hier gibt es genug Wasser","good":true,"reply":"Richtig. Was es überall gibt, ist für niemanden besonders wertvoll."},{"text":"Ja, Wasser ist immer gleich viel wert","good":false,"reply":"Wasser ist wichtig, aber hier gibt es so viel davon, dass niemand 5 Taler zahlen würde."}]},{"scene":[{"speaker":"talo","text":"Puh, der Aufstieg war heiß. Und oben auf dem Berg gibt es keine Quelle."}],"question":"Wie viel ist eine Flasche Wasser jetzt wert?","options":[{"text":"Viel, jetzt ist sie ein kleiner Schatz","good":true,"reply":"Genau. Dieselbe Flasche ist hier oben viel mehr wert, weil man sie dringend braucht."},{"text":"Genauso wenig wie unten am Strand","good":false,"reply":"Hier oben hat niemand Wasser, und alle haben Durst. Deshalb ist es jetzt viel wert."}]},{"scene":[{"speaker":"tala","text":"Ich liebe Fischbrötchen!"},{"speaker":"talo","text":"Ich mag gar keinen Fisch."}],"question":"Wem ist ein Fischbrötchen mehr wert?","options":[{"text":"Tala","good":true,"reply":"Richtig. Wert hängt auch davon ab, wer etwas bekommt."},{"text":"Beiden gleich viel","good":false,"reply":"Talo mag keinen Fisch. Für ihn ist das Fischbrötchen kaum etwas wert."}]},{"scene":[{"speaker":"tala","text":"Es regnet in Strömen, und ich habe meinen Schirm vergessen!"}],"question":"Wann ist ein Regenschirm am meisten wert?","options":[{"text":"Wenn es regnet und man keinen hat","good":true,"reply":"Genau. Wert hängt von der Person und der Situation ab."},{"text":"Bei Sonnenschein","good":false,"reply":"Bei Sonnenschein braucht ihn kaum jemand."}]}],"done":{"speaker":"talo","text":"Wert ist nicht für jeden gleich. Es kommt auf die Person und die Situation an."}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie viele Muscheln würdest du oben auf dem Berg für eine Flasche Wasser geben?","kind":"slider","min":0,"max":20,"start":2,"unit":"Muscheln","unit_one":"Muschel","reveal":{"speaker":"talo","text":"Da gibt es keine feste Antwort. Oben in der Hitze ist Wasser viel mehr wert als unten an der Quelle."}},"taps":[{"after":1,"kind":"tap","text":"Tipp auf die Sonne. Es wird heißer!","symbol":"sonne","done":"Puh! Jetzt ist Wasser noch mehr wert."},{"after":2,"kind":"drag","text":"Reich Tala die Wasserflasche.","symbol":"flasche","done":"Danke! Das war für mich gerade ein Schatz."}],"summary":{"speaker":"talo","text":"Wert ist nicht für jeden gleich. Er hängt von der Person und der Situation ab."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station3/q1')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Wann ist eine warme Jacke besonders viel wert?', '["An einem kalten Wintertag","Im Hochsommer am Strand","Wenn man schon zwei anhat"]'::jsonb, 0, 'Wer friert, schätzt eine Jacke viel mehr.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station3/q2')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Tala liebt Fischbrötchen, Talo nicht. Wer würde mehr dafür hergeben?', '["Tala","Talo","Beide gleich viel"]'::jsonb, 0, 'Wer etwas mag, ist bereit, mehr dafür zu geben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station3/q3')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Warum kann ein Tausch für beide gut sein?', '["Weil jeder das bekommt, was ihm mehr wert ist","Weil einer immer verliert","Weil beide genau gleich viel bekommen"]'::jsonb, 0, 'Dinge sind für verschiedene Menschen unterschiedlich viel wert.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station3/q4')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Ein Sonnenschirm am Strand im Hochsommer ist …', '["viel wert, weil viele Schatten brauchen.","genauso viel wert wie im Winter.","wertlos, weil es so viele davon gibt."]'::jsonb, 0, 'Wenn viele etwas brauchen, steigt sein Wert.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station3/q5')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Was beeinflusst, wie viel dir etwas wert ist?', '["Was du magst und was du gerade brauchst","Nur der Preis im Laden","Nur wie groß die Sache ist"]'::jsonb, 0, 'Vorlieben und die Situation bestimmen den Wert.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station3/q6')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Otti sammelt Muscheln, Bruno sammelt Honigtöpfe. Was zeigt das?', '["Jeder findet andere Dinge wertvoll.","Muscheln sind wertlos.","Honig ist immer mehr wert als Muscheln."]'::jsonb, 0, 'Was jemand sammelt oder mag, ist für ihn besonders wertvoll.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station4')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 40, 'game', true, 100, '{"title":"Wenn alle Eis wollen","number":4,"place":"Eisstand am Strand","goal":"Angebot und Nachfrage beeinflussen den Preis","minutes":"7 bis 10 Min.","scene":[{"speaker":"tala","text":"Darf ich heute den Eisstand übernehmen? Bitte, bitte!"},{"speaker":"talo","text":"Gern. Aber du bestimmst auch den Preis."},{"speaker":"tala","text":"Dann verlange ich ganz viel pro Kugel!"},{"speaker":"talo","text":"Mal sehen, wie viele Kunden dann kommen."}],"lesson":[{"speaker":"talo","text":"An heißen Tagen wollen viele ein Eis. Man sagt: Die Nachfrage ist groß.","image":"story.tauschinsel.4.1"},{"speaker":"tala","text":"Und wenn das Eis knapp wird, zahlen manche sogar mehr dafür!","image":"story.tauschinsel.4.2"},{"speaker":"talo","text":"An Regentagen will kaum jemand Eis. Dann muss der Preis runter, sonst bleibt das Eis liegen.","image":"story.tauschinsel.4.3"},{"speaker":"talo","text":"Angebot heißt: wie viel es von etwas gibt. Nachfrage heißt: wie viele es haben wollen. Beides beeinflusst den Preis.","image":"story.tauschinsel.4.4"}],"game":{"type":"choice","title":"Preise am Eisstand","description":"Setze den Preis für dein Eis an heißen und an verregneten Tagen und sieh, wie viele Kunden kommen.","task":"Du betreibst den Eisstand. Setze an jedem Tag einen Preis für eine Kugel und schau, was passiert.","rounds":[{"scene":[{"speaker":"tala","text":"Heute ist es heiß! Vor dem Stand steht eine lange Schlange. Wir haben nur noch 20 Kugeln."}],"question":"Welchen Preis setzt du für eine Kugel?","options":[{"text":"2 Taler","good":true,"reply":"Am Abend sind fast alle Kugeln verkauft. Wenn viele etwas wollen und es knapp ist, kann der Preis höher sein."},{"text":"1 Taler","good":false,"reply":"Nach wenigen Minuten ist alles weg, und viele gehen leer aus. Viele hätten auch mehr bezahlt."},{"text":"8 Taler","good":false,"reply":"So teuer will kaum jemand Eis. Die meisten gehen weiter, das Eis schmilzt."}]},{"scene":[{"speaker":"talo","text":"Heute regnet es. Kaum jemand ist am Strand, und wir haben viel Eis."}],"question":"Welchen Preis setzt du heute?","options":[{"text":"1 Taler","good":true,"reply":"Ein paar Leute kaufen trotzdem ein Eis. Wenn wenige etwas wollen, muss der Preis niedriger sein."},{"text":"3 Taler","good":false,"reply":"Bei Regen will kaum jemand Eis. Bei 3 Talern kauft heute niemand."}]},{"scene":[{"speaker":"tala","text":"An heißen Tagen ging das Eis weg wie nichts, bei Regen kaum."}],"question":"Was hast du am Eisstand gemerkt?","options":[{"text":"Wollen viele etwas, steigt der Preis. Wollen wenige etwas, sinkt er.","good":true,"reply":"Genau das nennt man Angebot und Nachfrage."},{"text":"Der Preis ist immer gleich","good":false,"reply":"Am heißen Tag und am Regentag hat ein anderer Preis gepasst."}]}],"done":{"speaker":"talo","text":"Wenn viele etwas wollen und es knapp ist, steigt der Preis. Wollen wenige etwas, sinkt er."}},"mini_game":{"type":"ice_stand","title":"Eisstand","description":"An drei Tagen den Preis für eine Kugel Eis setzen und sehen, wie viele kommen. So entdeckst du Angebot und Nachfrage.","task":"Du betreibst den Eisstand. Setze für jeden Tag einen Preis für eine Kugel und öffne den Stand. Findest du den Preis, mit dem du am meisten Taler einnimmst?","image":"story.tauschinsel.4.4","price_min":1,"price_max":8,"days":[{"weather":"sun","scene":[{"speaker":"tala","text":"Heute ist es heiß! Alle wollen Eis, und wir haben nur 20 Kugeln."}],"image":"story.tauschinsel.4.1","stock":20,"demand":40,"drop":5},{"weather":"clouds","scene":[{"speaker":"talo","text":"Heute ist es bewölkt. Nicht ganz so viele haben Lust auf Eis."}],"image":"game.ice_stand.clouds","stock":20,"demand":24,"drop":4},{"weather":"rain","scene":[{"speaker":"talo","text":"Heute regnet es. Kaum jemand ist am Strand, und wir haben wieder 20 Kugeln."}],"image":"story.tauschinsel.4.3","stock":20,"demand":10,"drop":2}],"done":{"speaker":"talo","text":"Wollen viele etwas und es ist knapp, kann der Preis steigen. Wollen wenige etwas, muss er sinken. Das nennt man Angebot und Nachfrage."}},"estimate":{"speaker":"tala","question":"Was glaubst du: Wie viele Kunden kommen an einem heißen Tag im Vergleich zu einem Regentag?","kind":"choice","options":["Gleich viele","Doppelt so viele","Viermal so viele"],"answer":2,"reveal":{"speaker":"talo","text":"Viermal so viele! An heißen Tagen wollen viel mehr Leute ein Eis."}},"taps":[{"after":2,"kind":"swipe","text":"Wisch von der Sonne zum Regen.","symbol":"regen","done":"Regen! Jetzt kommt kaum noch jemand."},{"after":3,"kind":"flip","text":"Dreh das Preisschild am Eisstand um.","symbol":"preisschild","back":"Regentag: Der Preis geht runter, damit das Eis nicht liegen bleibt."}],"summary":{"speaker":"tala","text":"Wollen viele etwas, das knapp ist, steigt der Preis. Will kaum jemand etwas, sinkt er."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station4/q1')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Es ist sehr heiß und alle wollen Eis. Wie nennt man das?', '["Große Nachfrage","Großes Angebot","Niedriger Preis"]'::jsonb, 0, 'Nachfrage bedeutet, wie viele etwas haben wollen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station4/q2')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Der Eisstand hat nur noch wenig Eis, aber viele Kunden. Was passiert oft?', '["Der Preis steigt.","Der Preis sinkt.","Der Preis bleibt immer gleich."]'::jsonb, 0, 'Ist etwas knapp und begehrt, steigt meist der Preis.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station4/q3')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'An einem Regentag kommt kaum jemand zum Eisstand. Was ist klug?', '["Den Preis senken oder weniger Eis machen","Den Preis verdoppeln","Mehr Eis herstellen"]'::jsonb, 0, 'Bei wenig Nachfrage sinkt der Preis oder man bietet weniger an.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station4/q4')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Was bedeutet „Angebot“?', '["Wie viel von etwas zu haben ist","Wie viele etwas haben wollen","Wie teuer etwas ist"]'::jsonb, 0, 'Das Angebot ist die Menge, die es zu kaufen gibt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station4/q5')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Am Eisstand gibt es 20 Kugeln. Bei 2 Talern wollen 30 Tiere ein Eis. Was passiert?', '["10 Tiere gehen leer aus.","Alle 30 bekommen ein Eis.","Es bleiben 10 Kugeln übrig."]'::jsonb, 0, 'Nur 20 Kugeln für 30 Tiere: 10 bekommen keins. Wollen mehr etwas, als da ist, kann der Preis steigen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station4/q6')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Tala verlangt für eine Kugel Eis einen sehr hohen Preis. Was passiert wahrscheinlich?', '["Weniger Kunden kaufen bei ihr.","Mehr Kunden kommen.","Sie verkauft trotzdem gleich viel."]'::jsonb, 0, 'Ist der Preis zu hoch, kaufen viele lieber nicht oder woanders.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station5')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 50, 'game', true, 100, '{"title":"Preis und Qualität","number":5,"place":"Werkstatt der Netzmacherin","goal":"Billig ist nicht immer günstig, vergleichen lohnt sich","minutes":"6 bis 9 Min.","scene":[{"speaker":"otti","text":"Mein Fischernetz ist schon wieder gerissen!","name":"Otti"},{"speaker":"greta","text":"Ich habe zwei Netze: eins für 5 Taler und eins für 20 Taler.","name":"Greta"},{"speaker":"otti","text":"Dann nehme ich natürlich das billige!","name":"Otti"},{"speaker":"greta","text":"Das billige hält aber nur einen Monat. Das teure ein ganzes Jahr.","name":"Greta"}],"lesson":[{"speaker":"talo","text":"Rechnen wir mal: Das billige Netz hält einen Monat. Für ein Jahr braucht Otti also 12 Stück.","image":"drawing:nets_year"},{"speaker":"tala","text":"12 mal 5 Taler sind 60 Taler! Das gute Netz kostet nur 20.","image":"drawing:nets_cost"},{"speaker":"talo","text":"Billig ist also nicht immer günstig. Wer vergleicht, wie lange etwas hält, spart oft Geld.","image":"story.tauschinsel.5.3"},{"speaker":"tala","text":"Aber teuer ist auch nicht automatisch gut. Vergleichen ist das Wichtigste!"}],"game":{"type":"number","title":"Netz-Rechnung","description":"Rechne aus, welches Netz über ein Jahr günstiger ist.","task":"Hilf Otti beim Rechnen. Tippe deine Antwort als Zahl ein.","rounds":[{"question":"Das billige Netz kostet 5 Taler und hält einen Monat. Wie viele Taler kostet es, ein ganzes Jahr lang immer ein billiges Netz zu haben?","amount":60,"unit":"Taler","hint":"Ein Jahr hat 12 Monate.","explanation":"12 Netze mal 5 Taler sind 60 Taler."},{"question":"Das gute Netz kostet 20 Taler und hält ein ganzes Jahr. Wie viele Taler spart Otti in einem Jahr mit dem guten Netz?","amount":40,"unit":"Taler","hint":"Rechne 60 minus 20.","explanation":"60 Taler minus 20 Taler sind 40 Taler. Das gute Netz ist am Ende günstiger."},{"question":"Eine billige Taucherbrille kostet 3 Taler und hält 3 Monate. Wie viele Taler kostet sie für ein ganzes Jahr?","amount":12,"unit":"Taler","hint":"Wie oft passen 3 Monate in ein Jahr?","explanation":"In ein Jahr passen 4 mal 3 Monate. 4 Brillen mal 3 Taler sind 12 Taler."}],"done":{"speaker":"otti","text":"Ich nehme das gute Netz. Billig ist nicht immer günstig!","name":"Otti"}},"estimate":{"speaker":"talo","question":"Was glaubst du: Welches Netz ist nach einem Jahr günstiger?","kind":"choice","options":["Das billige Netz für 5 Taler","Das gute Netz für 20 Taler"],"answer":1,"reveal":{"speaker":"tala","text":"Das gute! 12 billige Netze kosten im Jahr 60 Taler, das gute nur 20."}},"taps":[{"after":1,"kind":"drag","text":"Zieh kräftig am billigen Netz.","symbol":"netz","done":"Ratsch! Das billige Netz ist schon gerissen."},{"after":2,"kind":"tap","text":"Stapel die Taler für die billigen Netze: Tipp dreimal.","symbol":"muenze","count":3,"done":"Was für ein hoher Stapel!"}],"summary":{"speaker":"talo","text":"Billig ist nicht immer günstig. Vergleichen lohnt sich, auch wie lange etwas hält."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station5/q1')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Turnschuhe für 20 Taler halten ein halbes Jahr, Turnschuhe für 30 Taler ein ganzes Jahr. Was ist auf ein Jahr günstiger?', '["Die Turnschuhe für 30 Taler","Die Turnschuhe für 20 Taler","Beide kosten gleich viel"]'::jsonb, 0, 'Zwei billige Paare kosten 40 Taler, das gute Paar nur 30.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station5/q2')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Was solltest du beim Vergleichen außer dem Preis noch beachten?', '["Wie lange etwas hält","Wie bunt die Verpackung ist","Wie viele andere es schon gekauft haben"]'::jsonb, 0, 'Die Haltbarkeit gehört zum Vergleich dazu.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station5/q3')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Otti braucht im Jahr 12 Netze für je 5 Taler. Was kostet das?', '["60 Taler","17 Taler","5 Taler"]'::jsonb, 0, '12 mal 5 Taler sind 60 Taler.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station5/q4')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Ist etwas Teures immer besser?', '["Nein, vergleichen hilft.","Ja, teuer heißt immer gute Qualität.","Nein, das Billigste ist immer am besten."]'::jsonb, 0, 'Ein hoher Preis allein sagt nicht, dass etwas gut ist.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station5/q5')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Was bedeutet „günstig“?', '["Für das, was man bekommt, nicht zu viel bezahlen","Immer das Billigste nehmen","Etwas, das gerade im Angebot ist"]'::jsonb, 0, 'Günstig heißt: Preis und Leistung passen gut zusammen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station5/q6')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Ein Ball für 8 Taler hält 4 Monate, einer für 20 Taler ein ganzes Jahr. Was ist für ein Jahr günstiger?', '["Der Ball für 20 Taler","Der Ball für 8 Taler","Beide kosten gleich viel"]'::jsonb, 0, 'Vom billigen Ball braucht man im Jahr drei: 3 mal 8 Taler sind 24 Taler. Das ist mehr als 20 Taler.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station6')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 60, 'game', true, 100, '{"title":"Was ist mir etwas wert?","number":6,"place":"Aussichtsturm","goal":"Jede Entscheidung bedeutet einen Verzicht","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Oben auf dem Turm gibt es ein Fernrohr zu kaufen! Und unten den Eisstand."},{"speaker":"talo","text":"Du hast 5 Taler. Für beides reicht es nicht."},{"speaker":"tala","text":"Eis jetzt … oder sparen für das Fernrohr? Oh, ist das schwer!"}],"lesson":[{"speaker":"talo","text":"Geld kann man nur einmal ausgeben. Wer das Eis kauft, verzichtet aufs Sparen.","image":"story.tauschinsel.6.1"},{"speaker":"tala","text":"Und wer spart, verzichtet heute aufs Eis, hat aber später das Fernrohr.","image":"story.tauschinsel.6.2"},{"speaker":"talo","text":"Es gibt kein Richtig oder Falsch. Wichtig ist, dass du weißt, worauf du verzichtest.","image":"story.tauschinsel.6.3"}],"game":{"type":"choice","title":"Entscheidungen","description":"Triff mehrere Entscheidungen und sieh jedes Mal, worauf du verzichtest.","task":"Triff Entscheidungen und schau, worauf du jedes Mal verzichtest.","rounds":[{"scene":[{"speaker":"tala","text":"Ich habe 5 Taler. Ein Eis kostet 2 Taler. Aber ich spare doch auf das Fernrohr …"}],"question":"Was macht Tala?","options":[{"text":"Ein Eis kaufen","good":true,"reply":"Lecker! Dafür dauert es länger, bis das Fernrohr gekauft ist."},{"text":"Für das Fernrohr sparen","good":true,"reply":"Das Fernrohr rückt näher. Dafür gibt es heute kein Eis."}]},{"scene":[{"speaker":"talo","text":"Samstagnachmittag! Willst du mit den anderen am Strand spielen oder mir am Schiff helfen? Dafür bekommst du 2 Taler."}],"question":"Was machst du?","options":[{"text":"Am Strand spielen","good":true,"reply":"Ein schöner Nachmittag mit Freunden. Dafür gibt es keine 2 Taler."},{"text":"Am Schiff helfen","good":true,"reply":"2 Taler verdient! Dafür hast du heute nicht mit den anderen gespielt."}]},{"scene":[{"speaker":"tala","text":"Ich will alles: das Eis, das Fernrohr und auch noch frei haben!"}],"question":"Was stimmt bei jeder Entscheidung?","options":[{"text":"Man verzichtet immer auf etwas anderes","good":true,"reply":"Genau. Jede Entscheidung bedeutet einen Verzicht. Deshalb lohnt es sich, gut zu überlegen."},{"text":"Man kann immer alles haben","good":false,"reply":"Leider nicht. Geld und Zeit reichen nie für alles gleichzeitig."}]}],"done":{"speaker":"talo","text":"Jede Entscheidung bedeutet einen Verzicht. Überleg, was dir wichtiger ist."}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie viele Wochen muss Tala für das Fernrohr sparen?","kind":"wheel","min":1,"max":12,"start":2,"unit":"Wochen","unit_one":"Woche","answer":4,"reveal":{"speaker":"tala","text":"4 Wochen. Das Fernrohr kostet 20 Taler, und ich lege jede Woche meine 5 Taler zurück."}},"taps":[{"after":1,"kind":"drag","text":"Zieh den Taler zum Fernrohr.","symbol":"muenze","done":"Gespart! Das Eis muss heute warten."},{"after":2,"kind":"tap","text":"Schau durchs Fernrohr: Tipp darauf.","symbol":"fernrohr","done":"Was für eine Aussicht über das ganze Meer!"}],"summary":{"speaker":"tala","text":"Jede Entscheidung bedeutet einen Verzicht. Überleg dir, was dir wichtiger ist."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station6/q1')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Tala hat 5 Taler und kauft davon ein Eis für 5 Taler. Was kann sie danach nicht mehr?', '["Die 5 Taler fürs Fernrohr sparen","Das Eis essen","Auf den Turm steigen"]'::jsonb, 0, 'Geld kann man nur einmal ausgeben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station6/q2')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Was bedeutet „verzichten“?', '["Etwas nicht nehmen, um etwas anderes zu bekommen","Alles gleichzeitig kaufen","Etwas verschenken, das man nicht mag"]'::jsonb, 0, 'Wer sich entscheidet, verzichtet auf die andere Möglichkeit.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station6/q3')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Was hilft bei einer Entscheidung zwischen zwei Wünschen?', '["Überlegen, was mir wichtiger ist","Immer das Teurere nehmen","Gar nicht entscheiden"]'::jsonb, 0, 'Wer weiß, was ihm wichtig ist, entscheidet leichter.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station6/q4')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Tala spart mehrere Wochen, statt Eis zu kaufen. Was bekommt sie dafür?', '["Später das Fernrohr","Gar nichts","Das Eis und das Fernrohr"]'::jsonb, 0, 'Wer heute verzichtet, kann sich später etwas Größeres leisten.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station6/q5')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Gibt es bei „Eis oder Fernrohr“ eine richtige Antwort für alle?', '["Nein, das hängt davon ab, was einem wichtiger ist.","Ja, immer das Eis","Ja, immer das Fernrohr"]'::jsonb, 0, 'Jeder entscheidet nach dem, was ihm wichtig ist.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station6/q6')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Ein Eis kostet 2 Taler. Tala kauft jede Woche eins. Wie viel könnte sie in 5 Wochen stattdessen sparen?', '["10 Taler","7 Taler","2 Taler"]'::jsonb, 0, '5 Wochen mal 2 Taler sind 10 Taler. Kleine Ausgaben summieren sich.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station7')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 70, 'game', true, 100, '{"title":"Fair tauschen unter Freunden","number":7,"place":"Strandlager bei Olga","goal":"Ein fairer Tausch: Beide wissen, was sie bekommen, und sind einverstanden","minutes":"7 bis 10 Min.","scene":[{"speaker":"olga","text":"Willkommen, junge Crew. Bevor ich euch das Kartenstück gebe, möchte ich etwas sehen.","name":"Olga"},{"speaker":"tala","text":"Was denn?"},{"speaker":"olga","text":"Ob ihr fair tauschen könnt. Auf dem Schulhof gibt es nämlich nicht nur faire Tausche.","name":"Olga"}],"lesson":[{"speaker":"talo","text":"Stell dir vor: Ein älteres Kind will einem jüngeren eine seltene Sammelkarte gegen eine ganz häufige abschwatzen.","image":"story.tauschinsel.7.1"},{"speaker":"tala","text":"Das ist unfair! Das jüngere weiß gar nicht, wie selten seine Karte ist.","image":"story.tauschinsel.7.2"},{"speaker":"talo","text":"Fair ist ein Tausch, wenn beide wissen, was sie bekommen, und beide einverstanden sind.","image":"story.tauschinsel.7.3"},{"speaker":"olga","text":"Und wer vorher klärt, ob man zurücktauschen darf, hat später keinen Streit. Hier ist euer Kartenstück!","name":"Olga","image":"story.tauschinsel.7.4"}],"game":{"type":"sort","title":"Faire Tausche","description":"Erkenne faire und unfaire Tausche auf dem Schulhof.","task":"Ist dieser Tausch fair? Tippe auf eine Karte und dann auf den passenden Korb.","items":[{"text":"Mia tauscht zwei doppelte Karten gegen eine, die sie sich wünscht. Beide freuen sich.","basket":0},{"text":"Ein großes Kind sagt einem kleinen, seine seltene Karte sei nichts wert, und tauscht sie gegen eine alte.","basket":1,"hint":"Das große Kind hat das kleine getäuscht. Fair ist das nicht."},{"text":"Ben und Ali schauen sich die Karten genau an und sind beide einverstanden.","basket":0},{"text":"Lea drängelt: Tausch sofort, sonst bist du nicht mehr meine Freundin!","basket":1,"hint":"Wer droht, lässt dem anderen keine freie Wahl."},{"text":"Tim sagt vorher, dass seine Karte einen Knick hat. Jonas will trotzdem tauschen.","basket":0},{"text":"Noah verschweigt, dass an seiner Karte eine Ecke fehlt.","basket":1,"hint":"Wer etwas verschweigt, tauscht nicht fair."}],"baskets":["Fair","Nicht fair"],"done":{"speaker":"tala","text":"Fair ist ein Tausch, wenn beide wissen, was sie bekommen, und beide einverstanden sind."}},"estimate":{"speaker":"olga","question":"Was glaubst du: Wie viele häufige Karten ist eine seltene Karte wert?","kind":"slider","min":1,"max":10,"start":3,"unit":"Karten","unit_one":"Karte","reveal":{"speaker":"talo","text":"So viele, wie beide fair finden. Wichtig ist, dass beide wissen, wie selten die Karte ist."}},"taps":[{"after":1,"kind":"flip","text":"Dreh die Sammelkarten um.","symbol":"karte","back":"Eine Karte ist selten, die andere ganz häufig. Wusste das jüngere Kind das?"},{"after":3,"kind":"tap","text":"Schlag ein zum fairen Tausch: Tipp auf die Hand.","symbol":"hand","done":"Abgemacht! Beide sind einverstanden."}],"summary":{"speaker":"talo","text":"Ein fairer Tausch: Beide wissen, was sie bekommen, und sind einverstanden."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station7/q1')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Wann ist ein Tausch fair?', '["Wenn beide wissen, was sie bekommen, und einverstanden sind","Wenn einer den anderen austrickst","Wenn es besonders schnell geht"]'::jsonb, 0, 'Fair heißt ehrlich und freiwillig.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station7/q2')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Ein älteres Kind will einem jüngeren eine seltene Karte gegen eine häufige abschwatzen. Ist das fair?', '["Nein, weil das jüngere den Wert nicht kennt","Ja, Tausch ist Tausch","Ja, weil Ältere immer recht haben"]'::jsonb, 0, 'Wer den anderen über den Wert im Unklaren lässt, tauscht nicht fair.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station7/q3')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Was solltet ihr vor einem Tausch absprechen?', '["Ob man zurücktauschen darf","Wer von euch älter ist","Wer zuerst seine Karte zeigt"]'::jsonb, 0, 'Klare Absprachen verhindern späteren Streit.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station7/q4')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Dein Freund bietet dir einen unfairen Tausch an. Was kannst du tun?', '["Freundlich Nein sagen oder einen fairen Tausch vorschlagen","Trotzdem tauschen, damit er dein Freund bleibt","Ihm nie wieder etwas zeigen"]'::jsonb, 0, 'Man kann Nein sagen und trotzdem freundlich bleiben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station7/q5')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Warum gibt Olga der Crew das Kartenstück?', '["Weil die Crew fair getauscht hat","Weil Tala gebettelt hat","Weil Olga es loswerden wollte"]'::jsonb, 0, 'Olga wollte sehen, ob die Crew fair tauschen kann.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station7/q6')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Was gehört zu einem fairen Tausch?', '["Ehrlich sagen, wenn die eigene Sache einen Fehler hat","Fehler der eigenen Sache verschweigen","Den anderen unter Druck setzen"]'::jsonb, 0, 'Ehrlichkeit macht einen Tausch fair.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station8')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 80, 'exam', true, 150, '{"title":"Abschlussprüfung","number":8,"place":"Strandlager bei Olga","goal":"Alles von der Tauschinsel wiederholen, dazu zwei Fragen aus dem Hafen","minutes":"8 bis 10 Min.","scene":[{"speaker":"olga","text":"Zeigt mir, was ihr gelernt habt. Ab 8 richtigen Antworten gehört das Kartenstück euch.","name":"Olga"},{"speaker":"tala","text":"Zwei Fragen kommen sogar noch aus dem Hafen. Weißt du noch?"}],"summary":{"speaker":"olga","text":"Klug und fair, so soll eine Crew sein. Gute Fahrt zur Wunschinsel!","name":"Olga"},"exam":{"show":8,"review":2,"pass":8}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q1')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Warum konnte Tala auf der Tauschinsel nicht mit Talern bezahlen?', '["Weil dort niemand Geld annimmt","Weil die Taler zu wenig wert waren","Weil man dort nur mit Euro bezahlt"]'::jsonb, 0, 'Geld funktioniert nur, wenn alle es annehmen.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q2')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Greta will Äpfel, Tala hat nur Fisch. Was kann Tala tun?', '["Erst Fisch gegen Äpfel tauschen, dann Äpfel gegen das Seil","Das Seil einfach mitnehmen","Sofort aufgeben"]'::jsonb, 0, 'Über eine Tauschkette kommt man auch ans Ziel, wenn es länger dauert.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q3')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was ist eine Tauschkette?', '["Mehrere Tausche hintereinander, bis man hat, was man braucht","Ein Tausch, bei dem beide genau gleich viel bekommen","Ein Tausch mit vielen Leuten gleichzeitig"]'::jsonb, 0, 'Jeder Tausch ist ein Glied der Kette.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q4')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was solltest du dir vor einem Tausch überlegen?', '["Was ich wirklich brauche und was ich dafür hergebe","Welche Farbe der andere mag","Gar nichts, einfach schnell tauschen"]'::jsonb, 0, 'Wer vorher nachdenkt, macht bessere Tausche.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q5')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Woran erkennst du einen guten Tausch?', '["Am Ende sind beide zufrieden.","Nur einer hat gewonnen.","Einer ist traurig."]'::jsonb, 0, 'Ein guter Tausch ist für beide Seiten gut.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q6')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Wann ist eine Flasche Wasser besonders viel wert?', '["Nach einer langen Wanderung in der Hitze","Direkt nachdem man getrunken hat","Wenn man im Regen steht"]'::jsonb, 0, 'Der Wert hängt von der Situation ab.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q7')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Tala liebt Fischbrötchen, Talo mag sie nicht. Was zeigt das?', '["Dieselbe Sache ist nicht für jeden gleich viel wert.","Talo hat nie Hunger.","Fischbrötchen sind wertlos."]'::jsonb, 0, 'Jeder Mensch hat eigene Vorlieben, deshalb schätzt jeder Dinge anders.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q8')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Warum ist ein Regenschirm an einem Regentag mehr wert als bei Sonne?', '["Weil ihn dann viele brauchen","Weil Regenschirme dann teurer hergestellt werden","Weil er bei Sonne schneller kaputtgeht"]'::jsonb, 0, 'Wenn viele etwas brauchen, wird es wertvoller.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q9')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Es ist heiß, alle wollen Eis, aber es gibt nur wenig. Was passiert oft mit dem Preis?', '["Er steigt.","Er sinkt.","Das Eis wird verschenkt."]'::jsonb, 0, 'Viele wollen etwas, das knapp ist: Dann steigt meist der Preis.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q10')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Im Winter will kaum jemand Eis. Was macht der Eisverkäufer wahrscheinlich?', '["Er senkt den Preis oder verkauft weniger.","Er verdoppelt den Preis.","Er stellt mehr Eis her als im Sommer."]'::jsonb, 0, 'Wenig Nachfrage: Der Preis sinkt oder es wird weniger angeboten.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q11')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was bedeutet „Angebot“?', '["Wie viel von einer Sache zu haben ist","Wie viele etwas haben wollen","Wie teuer etwas ist"]'::jsonb, 0, 'Das Angebot ist die Menge, die verkauft wird.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q12')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was bedeutet „Nachfrage“?', '["Wie viele etwas haben wollen","Wie viel von einer Sache zu haben ist","Wie teuer etwas ist"]'::jsonb, 0, 'Die Nachfrage zeigt, wie begehrt etwas ist.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q13')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Ein Netz für 5 Taler hält einen Monat, eines für 20 Taler hält ein Jahr. Was ist auf ein Jahr gerechnet günstiger?', '["Das Netz für 20 Taler","Das Netz für 5 Taler","Beide kosten gleich viel"]'::jsonb, 0, '12 billige Netze kosten 60 Taler, das gute nur 20.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q14')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was bedeutet der Spruch „Wer billig kauft, kauft zweimal“?', '["Billige Dinge gehen manchmal schnell kaputt, dann muss man neu kaufen.","Man soll alles zweimal kaufen.","Billige Sachen sind immer schlecht."]'::jsonb, 0, 'Billig kann teuer werden. Aber nicht alles Billige ist schlecht, vergleichen hilft.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q15')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Ist das Teuerste immer das Beste?', '["Nein, man sollte vergleichen.","Ja, immer.","Nein, das Billigste ist immer besser."]'::jsonb, 0, 'Ein hoher Preis sagt noch nicht, dass etwas gut ist.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q16')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Tala hat 5 Taler: Eis jetzt oder sparen fürs Fernrohr. Was stimmt?', '["Kauft sie das Eis, verzichtet sie aufs Sparen.","Sie kann mit denselben 5 Talern beides haben.","Das spielt keine Rolle."]'::jsonb, 0, 'Geld kann man nur einmal ausgeben. Jede Entscheidung heißt Verzicht.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q17')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was hilft dir bei einer schwierigen Kaufentscheidung?', '["Überlegen, was mir wichtiger ist","Immer das Teurere nehmen","Das nehmen, was die anderen kaufen"]'::jsonb, 0, 'Wer weiß, was ihm wichtig ist, entscheidet leichter.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q18')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was ist ein fairer Tausch?', '["Beide wissen, was sie bekommen, und sind einverstanden.","Einer trickst den anderen aus.","Man nimmt dem Jüngeren etwas weg."]'::jsonb, 0, 'Fair heißt ehrlich und freiwillig.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q19')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Ein Freund will deine seltene Sammelkarte gegen eine ganz häufige tauschen. Was ist eine gute Reaktion?', '["Freundlich Nein sagen oder einen fairen Tausch vorschlagen","Sofort tauschen, damit er nicht sauer wird","Ihn auslachen"]'::jsonb, 0, 'Man darf Nein sagen und trotzdem freundlich bleiben.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/tauschinsel/station8/q20')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was solltet ihr vor einem Tausch unter Freunden klären?', '["Ob man den Tausch später rückgängig machen darf","Wer die seltenere Karte hat","Wer zuerst tauschen darf"]'::jsonb, 0, 'Klare Absprachen verhindern Streit.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

-- Ankerplatz 1: Das Wrack voller Waren
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/dive1')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 25, 'review_stop', true, 50, '{"title":"Das Wrack voller Waren","kind":"dive","number":1,"dive":{"game":"pearls","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Im Kapitänszimmer liegt ein alter Kompass! Aber der Krebs davor gibt ihn nur gegen ein Seil her."},{"speaker":"talo","text":"Wir haben einen Eimer. Der Fischer tauscht Fisch gegen einen Eimer, die Händlerin gibt ein Seil für Fisch."}],"question":"Wie kommt ihr an den Kompass?","answers":["Eimer gegen Fisch, Fisch gegen Seil, Seil gegen Kompass","Den Eimer direkt gegen den Kompass tauschen","Das Seil gegen Fisch und den Fisch gegen den Eimer tauschen"],"correct_index":0,"explanation":"Beim Tauschen braucht man oft Umwege, bis jeder bekommt, was er will. Mit Geld ginge es in einem Schritt."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/tauschinsel/dive1/find')::uuid, 'tauschinsel-fund-1', 'wreck_item', 'Alter Kompass', 'collectible.tauschinsel.1', md5('taleria:stage1/tauschinsel/dive1')::uuid, 21, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 2: Das Logbuch des Händlers
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/dive2')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 45, 'review_stop', true, 50, '{"title":"Das Logbuch des Händlers","kind":"dive","number":2,"dive":{"game":"fish_swarm","questions":4,"wreck":{"scene":[{"speaker":"talo","text":"Im Logbuch stehen Preise aus Sommer und Winter."},{"speaker":"tala","text":"Feuerholz kostete im Winter 3 Taler, im Sommer nur 1 Taler. Komisch!"}],"question":"Warum war Feuerholz im Winter teurer?","answers":["Im Winter wollten viele Leute Holz zum Heizen.","Im Winter war das Holz größer.","Der Händler hatte im Sommer schlechte Laune."],"correct_index":0,"explanation":"Wenn viele etwas haben wollen, steigt der Preis. Wert hängt von der Situation ab."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/tauschinsel/dive2/find')::uuid, 'tauschinsel-fund-2', 'wreck_item', 'Logbuch des Händlers', 'collectible.tauschinsel.2', md5('taleria:stage1/tauschinsel/dive2')::uuid, 22, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 3: Zwei Taucherbrillen
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/dive3')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 65, 'review_stop', true, 50, '{"title":"Zwei Taucherbrillen","kind":"dive","number":3,"dive":{"game":"treasure_chest","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Zwei Taucherbrillen! Die billige kostet 5 Taler, die gute 12 Taler."},{"speaker":"talo","text":"Im Zettel daneben steht: Die billige geht dreimal im Jahr kaputt, die gute hält das ganze Jahr."}],"question":"Welche Brille ist über ein Jahr günstiger?","answers":["Die gute, denn dreimal 5 Taler sind 15 Taler.","Die billige, denn 5 ist weniger als 12.","Beide kosten im Jahr gleich viel."],"correct_index":0,"explanation":"Billig kann teuer werden, wenn man öfter neu kaufen muss. Für die gute Brille verzichtest du am Anfang auf mehr Geld, sparst aber am Ende."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/tauschinsel/dive3/find')::uuid, 'tauschinsel-fund-3', 'wreck_item', 'Taucherbrille', 'collectible.tauschinsel.3', md5('taleria:stage1/tauschinsel/dive3')::uuid, 23, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

delete from public.quiz_questions q using public.stations s
where q.station_id = s.id and s.island_id = md5('taleria:stage1/tauschinsel')::uuid
  and q.id not in (md5('taleria:stage1/tauschinsel/sea1/q1')::uuid, md5('taleria:stage1/tauschinsel/sea1/q2')::uuid, md5('taleria:stage1/tauschinsel/sea1/q3')::uuid, md5('taleria:stage1/tauschinsel/sea1/q4')::uuid, md5('taleria:stage1/tauschinsel/sea1/q5')::uuid, md5('taleria:stage1/tauschinsel/sea1/q6')::uuid, md5('taleria:stage1/tauschinsel/sea2/q1')::uuid, md5('taleria:stage1/tauschinsel/sea2/q2')::uuid, md5('taleria:stage1/tauschinsel/sea2/q3')::uuid, md5('taleria:stage1/tauschinsel/sea2/q4')::uuid, md5('taleria:stage1/tauschinsel/sea2/q5')::uuid, md5('taleria:stage1/tauschinsel/sea2/q6')::uuid, md5('taleria:stage1/tauschinsel/station1/q1')::uuid, md5('taleria:stage1/tauschinsel/station1/q2')::uuid, md5('taleria:stage1/tauschinsel/station1/q3')::uuid, md5('taleria:stage1/tauschinsel/station1/q4')::uuid, md5('taleria:stage1/tauschinsel/station1/q5')::uuid, md5('taleria:stage1/tauschinsel/station1/q6')::uuid, md5('taleria:stage1/tauschinsel/station2/q1')::uuid, md5('taleria:stage1/tauschinsel/station2/q2')::uuid, md5('taleria:stage1/tauschinsel/station2/q3')::uuid, md5('taleria:stage1/tauschinsel/station2/q4')::uuid, md5('taleria:stage1/tauschinsel/station2/q5')::uuid, md5('taleria:stage1/tauschinsel/station2/q6')::uuid, md5('taleria:stage1/tauschinsel/station3/q1')::uuid, md5('taleria:stage1/tauschinsel/station3/q2')::uuid, md5('taleria:stage1/tauschinsel/station3/q3')::uuid, md5('taleria:stage1/tauschinsel/station3/q4')::uuid, md5('taleria:stage1/tauschinsel/station3/q5')::uuid, md5('taleria:stage1/tauschinsel/station3/q6')::uuid, md5('taleria:stage1/tauschinsel/station4/q1')::uuid, md5('taleria:stage1/tauschinsel/station4/q2')::uuid, md5('taleria:stage1/tauschinsel/station4/q3')::uuid, md5('taleria:stage1/tauschinsel/station4/q4')::uuid, md5('taleria:stage1/tauschinsel/station4/q5')::uuid, md5('taleria:stage1/tauschinsel/station4/q6')::uuid, md5('taleria:stage1/tauschinsel/station5/q1')::uuid, md5('taleria:stage1/tauschinsel/station5/q2')::uuid, md5('taleria:stage1/tauschinsel/station5/q3')::uuid, md5('taleria:stage1/tauschinsel/station5/q4')::uuid, md5('taleria:stage1/tauschinsel/station5/q5')::uuid, md5('taleria:stage1/tauschinsel/station5/q6')::uuid, md5('taleria:stage1/tauschinsel/station6/q1')::uuid, md5('taleria:stage1/tauschinsel/station6/q2')::uuid, md5('taleria:stage1/tauschinsel/station6/q3')::uuid, md5('taleria:stage1/tauschinsel/station6/q4')::uuid, md5('taleria:stage1/tauschinsel/station6/q5')::uuid, md5('taleria:stage1/tauschinsel/station6/q6')::uuid, md5('taleria:stage1/tauschinsel/station7/q1')::uuid, md5('taleria:stage1/tauschinsel/station7/q2')::uuid, md5('taleria:stage1/tauschinsel/station7/q3')::uuid, md5('taleria:stage1/tauschinsel/station7/q4')::uuid, md5('taleria:stage1/tauschinsel/station7/q5')::uuid, md5('taleria:stage1/tauschinsel/station7/q6')::uuid, md5('taleria:stage1/tauschinsel/station8/q1')::uuid, md5('taleria:stage1/tauschinsel/station8/q2')::uuid, md5('taleria:stage1/tauschinsel/station8/q3')::uuid, md5('taleria:stage1/tauschinsel/station8/q4')::uuid, md5('taleria:stage1/tauschinsel/station8/q5')::uuid, md5('taleria:stage1/tauschinsel/station8/q6')::uuid, md5('taleria:stage1/tauschinsel/station8/q7')::uuid, md5('taleria:stage1/tauschinsel/station8/q8')::uuid, md5('taleria:stage1/tauschinsel/station8/q9')::uuid, md5('taleria:stage1/tauschinsel/station8/q10')::uuid, md5('taleria:stage1/tauschinsel/station8/q11')::uuid, md5('taleria:stage1/tauschinsel/station8/q12')::uuid, md5('taleria:stage1/tauschinsel/station8/q13')::uuid, md5('taleria:stage1/tauschinsel/station8/q14')::uuid, md5('taleria:stage1/tauschinsel/station8/q15')::uuid, md5('taleria:stage1/tauschinsel/station8/q16')::uuid, md5('taleria:stage1/tauschinsel/station8/q17')::uuid, md5('taleria:stage1/tauschinsel/station8/q18')::uuid, md5('taleria:stage1/tauschinsel/station8/q19')::uuid, md5('taleria:stage1/tauschinsel/station8/q20')::uuid);

insert into public.badges (id, slug, kind, island_id, title, asset_key, sort_order, status)
values (md5('taleria:stage1/tauschinsel/badge')::uuid, 'tauschinsel', 'island', md5('taleria:stage1/tauschinsel')::uuid, 'Meistertauscher', 'badge.tauschinsel', 2, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, sort_order = excluded.sort_order,
  status = excluded.status;

insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/tauschinsel/prompt1')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 'Was hast du als Kind getauscht, und war es ein guter Tausch?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/tauschinsel/prompt2')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 'Gibt es etwas, das dir viel wert ist, für andere aber kaum etwas?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/tauschinsel/prompt3')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 'Wann musstest du zuletzt auf etwas verzichten, um dir etwas anderes leisten zu können?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/tauschinsel')::uuid and status <> 'draft';

-- 3. Wunschinsel, Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/wunschinsel')::uuid, 'wunschinsel', 1, 1, 3, 0.72, 0.84, 'main', 'Wunschinsel', '{"goal":"Das Kind unterscheidet Bedürfnisse und Wünsche, setzt Prioritäten, nutzt die Warte-Regel, erkennt Gruppendruck und weiß, dass Glück nicht nur von Dingen abhängt.","learn":["Was du wirklich brauchst und was du dir nur wünschst","Wie die Warte-Regel bei Wünschen hilft","Wie du Nein sagst, wenn andere drängeln"],"access":"premium","arrival":{"video_key":"video.arrival.wunschinsel","scene":[{"speaker":"tala","text":"Wow, hier glitzert und blinkt ja alles!"},{"speaker":"tala","text":"Das will ich! Und das! Und das!"},{"speaker":"elsa","text":"Alles zu haben, Schätzchen!","name":"Elsa"},{"speaker":"talo","text":"Moment. Was davon brauchst du wirklich?"},{"speaker":"talo","text":"Schau, im Wunschbrunnen leuchtet das nächste Kartenstück."}]},"badge":"Klarer Kompass","real_life_task":{"title":"Wunschflasche","text":"Steck einen Wunsch in die Wunschflasche und schau nach einer Woche mit deinen Eltern nach, ob du ihn noch willst."},"teaser":{"scene":[{"speaker":"talo","text":"Spürst du das? Es wird kühler, und bunte Blätter treiben auf dem Wasser."},{"speaker":"tala","text":"Herbst! Da wohnt bestimmt jemand, der fleißig Vorräte sammelt."}],"next_slug":"spar-insel","next_title":"Spar-Insel"}}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Stopp auf See 1: Gretas Händlerboot
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/sea1')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 1, 'sea_stop', true, 30, '{"title":"Gretas Händlerboot","kind":"sea_stop","stop":{"type":"haendlerschiff","figure":"greta","index":1,"ship":"ship.greta"},"scene":[{"speaker":"greta","text":"Ahoi! Ich bringe Seile zur Wunschinsel. Aber erst will ich wissen, ob ihr auf der Tauschinsel gut aufgepasst habt."},{"speaker":"talo","text":"Na klar. Stell uns deine Fragen!"}],"summary":{"speaker":"greta","text":"Ihr seid kluge Händler geworden! Gute Fahrt zur Wunschinsel."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea1/q1')::uuid, md5('taleria:stage1/wunschinsel/sea1')::uuid, 'Warum ist Wasser oben am heißen Berg mehr wert als unten an der Quelle?', '["Weil es oben knapp ist und man es dringend braucht","Weil Wasser oben anders schmeckt","Weil oben mehr Wasser da ist"]'::jsonb, 0, 'Wie viel etwas wert ist, hängt von der Situation ab. Was knapp ist und dringend gebraucht wird, ist mehr wert.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea1/q2')::uuid, md5('taleria:stage1/wunschinsel/sea1')::uuid, 'An einem heißen Tag wollen alle ein Eis. Was passiert oft mit dem Preis?', '["Er steigt.","Er sinkt.","Er bleibt gleich."]'::jsonb, 0, 'Wenn viele etwas haben wollen (große Nachfrage), steigt oft der Preis.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea1/q3')::uuid, md5('taleria:stage1/wunschinsel/sea1')::uuid, 'An einem Regentag will kaum jemand Eis. Was macht die Eisverkäuferin am besten?', '["Sie senkt den Preis.","Sie verdoppelt den Preis.","Sie macht mehr Eis."]'::jsonb, 0, 'Ist die Nachfrage klein, muss der Preis runter, sonst bleibt das Eis liegen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea1/q4')::uuid, md5('taleria:stage1/wunschinsel/sea1')::uuid, 'Ein billiges Netz kostet 5 Taler und hält einen Monat. Ein gutes kostet 20 Taler und hält ein Jahr. Was ist für ein Jahr günstiger?', '["Das gute Netz","Das billige Netz","Beide kosten gleich viel"]'::jsonb, 0, '12 billige Netze kosten 60 Taler, das gute nur 20. Billig ist nicht immer günstig.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea1/q5')::uuid, md5('taleria:stage1/wunschinsel/sea1')::uuid, 'Was heißt Angebot?', '["Wie viel es von etwas gibt","Wie viele etwas haben wollen","Wie teuer etwas ist"]'::jsonb, 0, 'Angebot heißt, wie viel es von etwas gibt. Nachfrage heißt, wie viele es haben wollen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea1/q6')::uuid, md5('taleria:stage1/wunschinsel/sea1')::uuid, 'Ist Teures automatisch gut?', '["Nein, man sollte vergleichen.","Ja, teuer ist immer am besten.","Nein, Billiges ist immer besser."]'::jsonb, 0, 'Teuer ist nicht automatisch gut. Vergleichen ist das Wichtigste.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;

-- Stopp auf See 2: Tala hat etwas vergessen
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/sea2')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 2, 'sea_stop', true, 30, '{"title":"Tala hat etwas vergessen","kind":"sea_stop","stop":{"type":"tala_vergisst","figure":"tala","index":2},"scene":[{"speaker":"tala","text":"Oh nein! Ich habe ganz vergessen, was wir auf der Tauschinsel über faires Tauschen gelernt haben."},{"speaker":"talo","text":"Kein Problem. Hilfst du Tala, sich zu erinnern?"}],"summary":{"speaker":"tala","text":"Danke, jetzt weiß ich es wieder! Auf zur Wunschinsel!"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea2/q1')::uuid, md5('taleria:stage1/wunschinsel/sea2')::uuid, 'Tala fragt: Woran erkenne ich einen fairen Tausch?', '["Wenn beide wissen, was sie bekommen, und einverstanden sind","Wenn einer viel mehr bekommt","Wenn der Ältere entscheidet"]'::jsonb, 0, 'Fair ist ein Tausch, wenn beide wissen, was sie bekommen, und beide einverstanden sind.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea2/q2')::uuid, md5('taleria:stage1/wunschinsel/sea2')::uuid, 'Ein älteres Kind will einem jüngeren eine seltene Karte gegen eine häufige abschwatzen. Was ist das?', '["Unfair, weil das jüngere den Wert nicht kennt","Fair, Tausch ist Tausch","Fair, wenn beide schnell zustimmen"]'::jsonb, 0, 'Das jüngere Kind weiß nicht, wie selten seine Karte ist. So ein Tausch ist unfair.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea2/q3')::uuid, md5('taleria:stage1/wunschinsel/sea2')::uuid, 'Was nennt man eine Tauschkette?', '["Mehrere Tausche hintereinander, bis man hat, was man braucht","Eine Kette, die man verschenkt","Einen Tausch ohne Gegenleistung"]'::jsonb, 0, 'Eimer gegen Fisch, Fisch gegen Äpfel, Äpfel gegen Seil: Das ist eine Tauschkette.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea2/q4')::uuid, md5('taleria:stage1/wunschinsel/sea2')::uuid, 'Was solltest du dich vor einem Tausch fragen?', '["Was brauche ich wirklich, und was gebe ich dafür her?","Was ist am teuersten?","Was haben meine Freunde?"]'::jsonb, 0, 'Vor einem Tausch lohnt sich die Frage: Was brauche ich wirklich, und was gebe ich dafür her?', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea2/q5')::uuid, md5('taleria:stage1/wunschinsel/sea2')::uuid, 'Wer sein Geld für ein Eis ausgibt, ...', '["kann es nicht mehr sparen.","hat danach mehr Geld.","bekommt das Geld zurück."]'::jsonb, 0, 'Geld kann man nur einmal ausgeben. Wer das Eis kauft, verzichtet aufs Sparen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/sea2/q6')::uuid, md5('taleria:stage1/wunschinsel/sea2')::uuid, 'Wie verhinderst du Streit nach einem Tausch?', '["Vorher klären, ob man zurücktauschen darf","Gar nicht darüber reden","Heimlich tauschen"]'::jsonb, 0, 'Wer vorher klärt, ob man zurücktauschen darf, hat später keinen Streit.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station1')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 10, 'game', true, 100, '{"title":"Bedürfnis oder Wunsch","number":1,"place":"Glitzerladen","goal":"Bedürfnisse kommen zuerst, Wünsche sind erlaubt","minutes":"6 bis 9 Min.","scene":[{"speaker":"elsa","text":"Willkommen im Glitzerladen! Alles glänzt, alles ist zu haben!","name":"Elsa"},{"speaker":"tala","text":"Das will ich! Und das! Und den Glitzerkompass!"},{"speaker":"talo","text":"Moment. Was davon brauchst du wirklich?"}],"lesson":[{"speaker":"talo","text":"Bedürfnisse sind Dinge, die man zum Leben braucht: Essen, Trinken, Kleidung und ein Zuhause.","image":"story.wunschinsel.1.1"},{"speaker":"tala","text":"Und Wünsche sind Dinge, die Spaß machen, aber nicht lebensnotwendig sind. Wie mein Glitzerkompass!","image":"story.wunschinsel.1.2"},{"speaker":"talo","text":"Manche Dinge liegen dazwischen, zum Beispiel ein Handy. Es kommt darauf an, wofür man es braucht.","image":"story.wunschinsel.1.3"},{"speaker":"tala","text":"Wünsche sind erlaubt! Aber Bedürfnisse kommen zuerst.","image":"story.wunschinsel.1.4"}],"game":{"type":"sort","title":"Zwei Körbe","description":"Sortiere Dinge in den Korb für Bedürfnisse oder für Wünsche.","task":"Tippe auf eine Karte und dann auf den passenden Korb.","items":[{"text":"Essen","basket":0},{"text":"Wasser","basket":0},{"text":"Eine warme Jacke im Winter","basket":0},{"text":"Ein Zuhause","basket":0},{"text":"Eine Spielkonsole","basket":1},{"text":"Ein Glitzerkompass","basket":1},{"text":"Das fünfte Paar Turnschuhe","basket":1},{"text":"Ein Handy","basket":null,"hint":"Darüber kann man streiten: Ein Handy hilft, die Eltern zu erreichen. Das neueste Modell ist aber ein Wunsch."}],"baskets":["Brauche ich","Wünsche ich mir"],"done":{"speaker":"talo","text":"Bedürfnisse kommen zuerst. Wünsche sind erlaubt, wenn das Wichtige da ist."}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie viele Dinge im Glitzerladen braucht man wirklich zum Leben?","kind":"choice","options":["Fast alle","Ungefähr die Hälfte","Fast keine"],"answer":2,"reveal":{"speaker":"talo","text":"Fast keine! Im Glitzerladen gibt es vor allem Wünsche. Zum Leben braucht man Essen, Trinken, Kleidung und ein Zuhause."}},"taps":[{"after":1,"kind":"swipe","text":"Wisch das Brot in den Korb „Brauche ich“.","symbol":"brot","done":"Richtig: Brot ist ein Bedürfnis."},{"after":2,"kind":"swipe","text":"Putz das Schaufenster: Wisch einmal darüber.","symbol":"besen","done":"Ohne Glitzer sieht man besser, was wirklich drin ist."}],"summary":{"speaker":"tala","text":"Bedürfnisse kommen zuerst, Wünsche sind erlaubt."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station1/q1')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Welches davon ist ein Bedürfnis?', '["Eine Regenjacke für den Schulweg im Herbst","Eine zweite Regenjacke in der Lieblingsfarbe","Ein neues Videospiel"]'::jsonb, 0, 'Gegen Regen braucht man eine Jacke. Eine zweite in der Lieblingsfarbe ist schön, aber ein Wunsch.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station1/q2')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Welches davon ist ein Wunsch?', '["Markenturnschuhe, obwohl die alten noch passen","Neue Schuhe, weil die alten zu klein sind","Ein Pausenbrot für die Schule"]'::jsonb, 0, 'Passende Schuhe und Essen braucht man. Neue Markenschuhe, obwohl die alten passen, sind ein Wunsch.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station1/q3')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Was kommt zuerst, wenn das Geld knapp ist?', '["Die Bedürfnisse","Die Wünsche","Das, was gerade im Angebot ist"]'::jsonb, 0, 'Erst das Nötige, dann das Schöne.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station1/q4')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Sind Wünsche schlecht?', '["Nein, Wünsche sind erlaubt.","Ja, man sollte nur Bedürfnisse kaufen.","Nein, Wünsche gehen immer vor."]'::jsonb, 0, 'Wünsche sind in Ordnung, wenn die Bedürfnisse gedeckt sind.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station1/q5')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Warum ist ein Handy schwer einzuordnen?', '["Weil es je nach Situation Bedürfnis oder Wunsch sein kann","Weil es sehr teuer ist","Weil es fast jeder hat"]'::jsonb, 0, 'Für manche ist es nötig, etwa um die Eltern zu erreichen, für andere vor allem Spaß.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station1/q6')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Warme Winterstiefel im Dezember sind …', '["ein Bedürfnis.","ein Wunsch, weil sie teuer sind.","unwichtig, weil der Winter kurz ist."]'::jsonb, 0, 'Im Winter braucht man warme Schuhe.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station2')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 20, 'game', true, 100, '{"title":"Prioritäten setzen","number":2,"place":"Packhaus","goal":"Wenn das Geld nicht für alles reicht, entscheidet man nach Wichtigkeit","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Ich darf einen Rucksack für die Wanderung packen! Aber nur für 10 Taler."},{"speaker":"talo","text":"Und auf der Liste stehen Sachen für viel mehr als 10 Taler."},{"speaker":"tala","text":"Oh nein, ich will alles mitnehmen!"}],"lesson":[{"speaker":"talo","text":"Wenn das Geld nicht für alles reicht, muss man auswählen.","image":"story.wunschinsel.2.1"},{"speaker":"talo","text":"Prioritäten setzen heißt: Das Wichtigste kommt zuerst in den Rucksack.","image":"story.wunschinsel.2.2"},{"speaker":"tala","text":"Also erst Wasser und Proviant, dann vielleicht die Glitzersonnenbrille."},{"speaker":"talo","text":"Und wer sich für etwas entscheidet, verzichtet auf etwas anderes.","image":"story.wunschinsel.2.3"}],"game":{"type":"pick","title":"Rucksack packen","description":"Packe Talas Rucksack mit 10 Talern. Das Wichtigste zuerst.","task":"Tala hat 10 Taler für ihren Rucksack. Tippe an, was sie mitnimmt. Das Wichtigste zuerst!","items":[{"text":"Wasserflasche","price":2,"required":true,"hint":"Ohne Wasser wird die Reise schwer. Die Wasserflasche gehört hinein."},{"text":"Brot für unterwegs","price":3,"required":true,"hint":"Unterwegs braucht Tala etwas zu essen."},{"text":"Regenjacke","price":4,"required":true,"hint":"Wenn es regnet, ist Tala froh über die Regenjacke."},{"text":"Glitzerkompass","price":6,"required":false,"hint":"Schön, aber nicht wichtig für die Reise."},{"text":"Comic","price":2,"required":false,"hint":"Nett zum Lesen, aber nicht das Wichtigste."},{"text":"Bonbons","price":1,"required":false,"hint":"Lecker, aber nicht das Wichtigste."}],"target":10,"exact":false,"done":{"speaker":"talo","text":"Zuerst das Wichtige, dann vom Rest, was noch passt. So reicht das Geld für die Reise."}},"mini_game":{"type":"backpack","title":"Talas Ausflüge","description":"Packe für drei Ausflüge, was Tala wirklich braucht.","task":"Tala macht drei Ausflüge. Für jeden hat sie ein paar Taler. Lies genau, wohin es geht, und pack ein, was sie wirklich braucht. Dann tippe auf „Losgehen“.","image":"game.backpack","images":{"Wasserflasche":"item.wasserflasche","Brötchen":"item.broetchen","Regenjacke":"item.regenjacke","Sonnenhut":"item.sonnenhut","Taschenlampe":"item.taschenlampe","Glitzer-Sonnenbrille":"item.glitzerbrille","Fernglas":"item.fernglas","Kissen":"item.kissen","Bonbons":"item.bonbons"},"items":[{"text":"Wasserflasche","price":2},{"text":"Brötchen","price":2},{"text":"Regenjacke","price":4},{"text":"Sonnenhut","price":2},{"text":"Taschenlampe","price":3},{"text":"Glitzer-Sonnenbrille","price":4},{"text":"Fernglas","price":5},{"text":"Kissen","price":3},{"text":"Bonbons","price":1}],"trips":[{"title":"Wanderung zum Wasserfall","scene":[{"speaker":"tala","text":"Heute wandern wir den ganzen Tag bis zum Wasserfall!"},{"speaker":"talo","text":"Schau mal zum Himmel. Die Wolken sind ganz dunkel."}],"image":"game.backpack.waterfall","budget":10,"needs":[{"item":"Regenjacke","missing":"Es fängt an zu regnen. Ohne Regenjacke wird Tala klatschnass."},{"item":"Wasserflasche","missing":"Der Weg ist lang. Ohne Wasser bekommt Tala großen Durst."},{"item":"Brötchen","missing":"Mittags knurrt Talas Magen, aber sie hat nichts zu essen dabei."}]},{"title":"Ein Tag am Strand","scene":[{"speaker":"tala","text":"Ab an den Strand! Die Sonne scheint, kein Wölkchen am Himmel."},{"speaker":"talo","text":"Wir bleiben bis zum Nachmittag. Es wird richtig heiß."}],"image":"game.backpack.beach","budget":7,"needs":[{"item":"Sonnenhut","missing":"Die Sonne brennt auf Talas Kopf. Ohne Sonnenhut wird ihr schwindelig."},{"item":"Wasserflasche","missing":"Es ist heiß. Ohne Wasser bekommt Tala großen Durst."},{"item":"Brötchen","missing":"Bis zum Nachmittag ist es lang. Tala hat Hunger und nichts zu essen."}]},{"title":"Nachts zum Leuchtturm","scene":[{"speaker":"talo","text":"Heute Abend gehen wir zum Leuchtturm und schauen uns die Sterne an. Es ist nicht weit."},{"speaker":"tala","text":"Aber es wird stockdunkel. Und oben am Leuchtturm pfeift nachts ein kalter Wind."}],"image":"game.backpack.night","budget":8,"needs":[{"item":"Taschenlampe","missing":"Es ist stockdunkel. Ohne Taschenlampe stolpert Tala über eine Wurzel."},{"item":"Regenjacke","missing":"Oben am Leuchtturm weht ein kalter Wind. Ohne Jacke friert Tala."}]}],"done":{"speaker":"talo","text":"Was man wirklich braucht, hängt davon ab, wohin es geht. Und was übrig bleibt, kann man sparen."}},"estimate":{"speaker":"tala","question":"Was glaubst du: Wie viele wichtige Dinge passen für 10 Taler in meinen Rucksack?","kind":"wheel","min":0,"max":8,"start":5,"unit":"Dinge","unit_one":"Ding","answer":3,"reveal":{"speaker":"talo","text":"Drei: Wasserflasche, Brot und Regenjacke kosten zusammen 9 Taler. Für Glitzerkram bleibt dann kaum etwas übrig."}},"taps":[{"after":2,"kind":"drag","text":"Pack die Wasserflasche in den Rucksack.","symbol":"flasche","done":"Das Wichtigste zuerst!"},{"after":3,"kind":"drag","text":"Nimm die Glitzersonnenbrille wieder heraus.","symbol":"stern","done":"Schade, aber dafür reicht das Geld nicht."}],"summary":{"speaker":"talo","text":"Reicht das Geld nicht für alles, entscheidet man nach Wichtigkeit."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station2/q1')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Du hast 10 Taler. Wasser kostet 2, Proviant 4, eine Glitzerbrille 6. Was packst du für eine Wanderung ein?', '["Wasser und Proviant","Nur die Glitzerbrille","Alles, auch wenn das Geld nicht reicht"]'::jsonb, 0, 'Wasser und Proviant kosten zusammen 6 Taler und sind am wichtigsten. Für die Brille reicht es dann nicht mehr.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station2/q2')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Was bedeutet „Prioritäten setzen“?', '["Das Wichtigste zuerst","Das Billigste zuerst","Das, was am meisten Spaß macht, zuerst"]'::jsonb, 0, 'Prioritäten zeigen, was am wichtigsten ist.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station2/q3')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Tala hat 12 Taler. Wasser kostet 3, Proviant 4, eine Taschenlampe 5, eine Glitzerbrille 6. Wasser und Proviant müssen mit. Was passt noch?', '["Die Taschenlampe","Die Glitzerbrille","Taschenlampe und Glitzerbrille"]'::jsonb, 0, 'Wasser und Proviant kosten 7 Taler, es bleiben 5. Das reicht genau für die Taschenlampe.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station2/q4')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Tala packt die Glitzerbrille statt Proviant ein. Was ist das Problem?', '["Auf der Wanderung fehlt ihr etwas Wichtiges.","Es gibt kein Problem.","Die Brille war zu billig."]'::jsonb, 0, 'Wer Unwichtiges zuerst kauft, hat für Wichtiges kein Geld mehr.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station2/q5')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Wie kannst du deine Wünsche ordnen?', '["Nach Wichtigkeit, das Wichtigste oben","Nach dem Preis, das Teuerste oben","Nach dem, was Freunde gut finden"]'::jsonb, 0, 'Eine Reihenfolge nach Wichtigkeit hilft beim Entscheiden.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station2/q6')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Wenn du dich für einen Wunsch entscheidest, …', '["verzichtest du auf einen anderen.","bekommst du alle anderen gratis.","bleibt das Geld trotzdem da."]'::jsonb, 0, 'Geld kann man nur einmal ausgeben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station3')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 30, 'game', true, 100, '{"title":"Die Warte-Regel","number":3,"place":"Wunschflaschen-Strand","goal":"Warten zeigt, ob man etwas wirklich will","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Den Glitzerkompass kaufe ich sofort! Jetzt gleich!"},{"speaker":"talo","text":"Warte mal. Kennst du die Warte-Regel?"},{"speaker":"tala","text":"Die Warte-was?"}],"lesson":[{"speaker":"talo","text":"Bei kleinen Wünschen schläfst du eine Nacht drüber. Bei großen eine ganze Woche.","image":"story.wunschinsel.3.1"},{"speaker":"tala","text":"Und wenn ich es danach immer noch will?"},{"speaker":"talo","text":"Dann ist es ein echter Wunsch. Viele Wünsche sind nach ein paar Tagen aber einfach verschwunden.","image":"story.wunschinsel.3.2"},{"speaker":"tala","text":"Ich stecke meinen Wunsch in eine Wunschflasche! Dann fragt mich die App später, ob ich ihn noch will.","image":"story.wunschinsel.3.3"}],"game":{"type":"wish_bottle","title":"Wunschflasche","description":"Steck einen eigenen Wunsch in eine Wunschflasche. Die App fragt später nach, ob du ihn noch willst."},"estimate":{"speaker":"talo","question":"Tala hat 10 Wünsche. Was glaubst du: Wie viele will sie nach einer Woche noch?","kind":"wheel","min":0,"max":10,"start":8,"unit":"Wünsche","unit_one":"Wunsch","answer":3,"reveal":{"speaker":"tala","text":"Nur noch 3! Die anderen sind einfach verschwunden. Darum lohnt sich die Warte-Regel."}},"taps":[{"after":3,"kind":"drag","text":"Steck den Wunsch in die Wunschflasche.","symbol":"liste","done":"Der Korken ist drauf."},{"after":4,"kind":"swipe","text":"Wirf die Flasche ins Meer: Wisch nach rechts.","symbol":"flasche","done":"Platsch! Jetzt heißt es warten."}],"summary":{"speaker":"talo","text":"Warten zeigt, ob man etwas wirklich will."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station3/q1')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Was sagt die Warte-Regel?', '["Vor einem Kauf erst drüber schlafen","Immer sofort kaufen","Nie etwas kaufen"]'::jsonb, 0, 'Mit etwas Abstand entscheidet man besser.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station3/q2')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Wie lange wartest du ungefähr bei einem kleinen Wunsch?', '["Eine Nacht","Eine Woche","Einen Monat"]'::jsonb, 0, 'Bei kleinen Wünschen reicht eine Nacht.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station3/q3')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Wie lange wartest du ungefähr bei einem großen Wunsch?', '["Eine Woche","Eine Nacht","Ein ganzes Jahr"]'::jsonb, 0, 'Je größer der Wunsch, desto länger lohnt sich das Überlegen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station3/q4')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Was passiert oft mit Wünschen, wenn man wartet?', '["Manche verschwinden von selbst.","Sie werden immer stärker.","Sie werden automatisch billiger."]'::jsonb, 0, 'Viele Wünsche sind nach ein paar Tagen gar nicht mehr wichtig.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station3/q5')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Tala will den Kompass nach einer Woche immer noch. Was bedeutet das?', '["Es ist ein echter Wunsch.","Sie muss noch ein Jahr warten.","Sie sollte ihn sofort vergessen."]'::jsonb, 0, 'Bleibt der Wunsch, kann man überlegen, dafür zu sparen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station3/q6')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Wozu ist die Wunschflasche gut?', '["Um einen Wunsch aufzuschreiben und später noch einmal zu prüfen","Damit der Wunsch schneller in Erfüllung geht","Damit man den Wunsch vergisst"]'::jsonb, 0, 'Die Wunschflasche hilft beim Warten.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station4')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 40, 'game', true, 100, '{"title":"Alle haben das","number":4,"place":"Möwenplatz","goal":"Gruppendruck erkennen und Nein sagen können","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Guck mal, alle Möwen tragen rote Mützen! Ich brauche auch eine!"},{"speaker":"talo","text":"Brauchst du sie wirklich, oder willst du nur dazugehören?"},{"speaker":"tala","text":"Hmm … gestern wollte ich noch gar keine."}],"lesson":[{"speaker":"talo","text":"Wenn man etwas tut, weil alle anderen es tun oder erwarten, nennt man das Gruppendruck.","image":"story.wunschinsel.4.1"},{"speaker":"tala","text":"Gruppendruck kann dazu führen, dass man Sachen kauft, die man eigentlich gar nicht will.","image":"story.wunschinsel.4.2"},{"speaker":"talo","text":"Eine gute Frage ist: Würde ich das auch wollen, wenn es niemand sonst hätte?","image":"story.wunschinsel.4.3"},{"speaker":"tala","text":"Und man darf freundlich Nein sagen. Das ist sogar ziemlich stark!","image":"story.wunschinsel.4.4"}],"game":{"type":"sort","title":"Gruppendruck erkennen","description":"Erkenne Situationen mit Gruppendruck.","task":"Ist das Gruppendruck oder eine eigene Entscheidung? Tippe auf eine Karte und dann auf den passenden Korb.","items":[{"text":"Alle Möwen tragen rote Mützen. Tala will plötzlich auch eine, obwohl sie Mützen nicht mag.","basket":0},{"text":"Lina spart für ein Fahrrad, weil sie gern Rad fährt.","basket":1},{"text":"Ben kauft das teure Spiel, weil die anderen sonst über ihn lachen.","basket":0},{"text":"Mo schläft eine Nacht drüber und entscheidet dann, ob er die Sammelkarten wirklich will.","basket":1},{"text":"In der Klasse heißt es: Wer die Marken-Turnschuhe nicht hat, gehört nicht dazu.","basket":0},{"text":"Ella sagt: Danke, ich brauche das nicht. Und sie bleibt dabei.","basket":1}],"baskets":["Gruppendruck","Eigene Entscheidung"],"done":{"speaker":"tala","text":"Gruppendruck erkennen ist der erste Schritt. Dann darfst du ruhig Nein sagen."}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie viele Möwen tragen eine Woche später noch die rote Mütze?","kind":"choice","options":["Alle","Ungefähr die Hälfte","Fast keine"],"answer":2,"reveal":{"speaker":"tala","text":"Fast keine! Die Mützen waren nur kurz beliebt. Gut, dass ich keine gekauft habe."}},"taps":[{"after":3,"kind":"drag","text":"Nimm Tala die rote Mütze ab.","symbol":"kleidung","done":"Viel besser! Tala sieht wieder aus wie Tala."},{"after":4,"kind":"tap","text":"Daumen hoch fürs freundliche Nein-Sagen!","symbol":"daumen","done":"Stark!"}],"summary":{"speaker":"tala","text":"Gruppendruck erkennen und Nein sagen können, das macht stark."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station4/q1')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Alle in der Klasse haben dieselben Turnschuhe. Welche Frage hilft dir?', '["Würde ich sie auch wollen, wenn sie niemand hätte?","Wie viel kosten sie bei den anderen?","Wer hat die teuersten?"]'::jsonb, 0, 'Diese Frage zeigt, ob man etwas wirklich will.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station4/q2')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Was ist Gruppendruck?', '["Wenn man etwas tut, weil andere es erwarten","Wenn eine Gruppe gemeinsam einkauft","Wenn man allein entscheidet, was man will"]'::jsonb, 0, 'Gruppendruck kann zu Entscheidungen führen, die man eigentlich nicht will.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station4/q3')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Was ist eine gute Antwort, wenn dich jemand drängt, etwas zu kaufen?', '["„Nein danke, das brauche ich nicht.“","„Okay, damit ihr mich mögt.“","„Ich schaue, was es kostet, und kaufe es dann.“"]'::jsonb, 0, 'Ein freundliches Nein ist stark.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station4/q4')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Warum wollte Tala plötzlich eine rote Mütze?', '["Weil alle Möwen eine trugen","Weil ihr kalt war","Weil die Mütze im Angebot war"]'::jsonb, 0, 'Sie wollte dazugehören, nicht weil sie die Mütze brauchte.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station4/q5')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Ist es schlimm, nicht alles zu haben, was andere haben?', '["Nein, jeder darf eigene Entscheidungen treffen.","Ja, man gehört sonst nicht dazu.","Nur bei Kleidung ist das schlimm."]'::jsonb, 0, 'Echte Freunde mögen dich wegen dir, nicht wegen deiner Sachen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station4/q6')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Woran merkst du, dass du unter Gruppendruck stehst?', '["Du willst etwas nur, weil andere es haben.","Du hast lange darüber nachgedacht.","Du brauchst es für die Schule."]'::jsonb, 0, 'Kommt der Wunsch nur von den anderen, ist das Gruppendruck.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station5')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 50, 'game', true, 100, '{"title":"Macht Geld glücklich?","number":5,"place":"Moritz'' Höhle","goal":"Geld hilft, aber Glück hat viele Quellen","minutes":"6 bis 9 Min.","scene":[{"speaker":"moritz","text":"Kommt rein, kommt rein! Viel habe ich nicht, aber es ist gemütlich.","name":"Moritz"},{"speaker":"tala","text":"Du hast ja fast gar nichts! Bist du nicht traurig?"},{"speaker":"moritz","text":"Traurig? Ich habe meine Freunde, meine Sonnenplätze und meine Murmelsammlung. Ich bin sehr zufrieden.","name":"Moritz"}],"lesson":[{"speaker":"talo","text":"Geld ist wichtig. Es kann Sorgen nehmen, zum Beispiel um Essen oder ein Zuhause.","image":"story.wunschinsel.5.1"},{"speaker":"tala","text":"Aber die Freude über neue Sachen hält oft nicht lange. Mein Glitzerkompass wäre nach einer Woche bestimmt ganz normal.","image":"story.wunschinsel.5.2"},{"speaker":"talo","text":"Freunde, gemeinsame Zeit und Gesundheit machen auch glücklich. Die kann man nicht kaufen.","image":"story.wunschinsel.5.3"}],"game":{"type":"choice","title":"Gespräch mit Moritz","description":"Unterhalte dich mit Moritz darüber, was ihn glücklich macht.","task":"Unterhalte dich mit Moritz. Es gibt keine falschen Fragen, nur eine Frage zum Schluss.","rounds":[{"scene":[{"speaker":"moritz","text":"Willkommen in meiner Höhle! Viel habe ich nicht: ein Buch, eine Decke und gute Freunde. Und ich bin glücklich.","name":"Moritz"}],"question":"Was fragst du Moritz?","options":[{"text":"Was macht dich glücklich?","good":true,"reply":"Moritz: „Zeit mit Freunden, die Sonne am Morgen und ein gutes Buch.“"},{"text":"Wünschst du dir nicht mehr Sachen?","good":true,"reply":"Moritz: „Manchmal schon. Aber die Freude über neue Sachen ist schnell vorbei.“"}]},{"scene":[{"speaker":"moritz","text":"Und du? Was macht dich glücklich?","name":"Moritz"}],"question":"Was antwortest du?","options":[{"text":"Zeit mit meiner Familie und meinen Freunden","good":true,"reply":"Moritz: „Das kenne ich. So etwas kann man nicht kaufen.“"},{"text":"Etwas Neues zu bekommen","good":true,"reply":"Moritz: „Die Freude ist echt. Aber merk dir, wie lange sie hält.“"},{"text":"Draußen spielen","good":true,"reply":"Moritz: „Oh ja! Und das kostet nicht einmal etwas.“"}]},{"scene":[{"speaker":"talo","text":"Geld kann Sorgen nehmen. Aber macht es allein glücklich?"}],"question":"Was stimmt?","options":[{"text":"Geld hilft, aber Glück hat viele Quellen","good":true,"reply":"Genau: Freunde, Zeit und Gesundheit zählen auch."},{"text":"Nur wer viel Geld hat, ist glücklich","good":false,"reply":"Moritz hat wenig und ist trotzdem glücklich."}]}],"done":{"speaker":"moritz","text":"Danke für das Gespräch! Pass auf dich auf, junge Crew.","name":"Moritz"}},"estimate":{"speaker":"moritz","question":"Was glaubst du: Wie viele Tage freut sich Tala über ein neues Spielzeug?","kind":"wheel","min":1,"max":30,"start":10,"unit":"Tage","unit_one":"Tag","answer":2,"reveal":{"speaker":"tala","text":"Nur 2 Tage! Danach war es ganz normal. Freunde und gemeinsame Zeit machen länger froh."}},"taps":[{"after":2,"kind":"drag","text":"Leg das Spielzeug in die Ecke.","symbol":"spielzeug","done":"Da liegt es jetzt …"},{"after":3,"kind":"tap","text":"Wink Moritz zu.","symbol":"winken","done":"Moritz winkt fröhlich zurück."}],"summary":{"speaker":"talo","text":"Geld hilft, aber Glück hat viele Quellen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station5/q1')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Wobei kann Geld helfen?', '["Es kann Sorgen nehmen, zum Beispiel ums Essen.","Es kann Freunde kaufen.","Es macht immer glücklich."]'::jsonb, 0, 'Geld hilft bei vielen Dingen, aber nicht bei allem.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station5/q2')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Warum ist Moritz zufrieden, obwohl er wenig besitzt?', '["Weil er Freunde und schöne Zeit hat","Weil er heimlich reich ist","Weil er nicht weiß, was man kaufen kann"]'::jsonb, 0, 'Glück hängt nicht nur vom Besitz ab.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station5/q3')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Was passiert oft mit der Freude über etwas Neues?', '["Sie wird mit der Zeit kleiner.","Sie wird jeden Tag größer.","Sie bleibt für immer gleich."]'::jsonb, 0, 'Man gewöhnt sich schnell an Neues.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station5/q4')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Was davon kann man nicht kaufen?', '["Echte Freundschaft","Ein Kinoticket für einen Ausflug","Ein Geschenk für eine Freundin"]'::jsonb, 0, 'Mit Geld kann man etwas für Freunde kaufen. Die Freundschaft selbst kann man nicht kaufen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station5/q5')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Welcher Satz stimmt?', '["Geld ist wichtig, aber nicht das Einzige, was glücklich macht.","Nur Geld macht glücklich.","Geld ist völlig unwichtig."]'::jsonb, 0, 'Geld und Glück hängen zusammen, aber nicht nur.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station5/q6')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Was macht viele Menschen glücklich?', '["Zeit mit Familie und Freunden","Möglichst viele neue Sachen","Immer das Neueste zu haben"]'::jsonb, 0, 'Gemeinsame Zeit gehört für viele zu den schönsten Dingen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station6')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 60, 'game', true, 100, '{"title":"Erlebnisse statt Dinge","number":6,"place":"Erinnerungsfelsen","goal":"Erlebnisse bleiben oft länger in Erinnerung","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Was ist das für ein Felsen? Da sind überall Bilder eingeritzt!"},{"speaker":"talo","text":"Das ist der Erinnerungsfelsen. Hier halten die Inselbewohner ihre schönsten Erlebnisse fest."},{"speaker":"tala","text":"Kein einziges Bild von einem Spielzeug. Nur Ausflüge, Feste und Freunde!"}],"lesson":[{"speaker":"talo","text":"Ein neues Spielzeug ist toll, aber oft liegt es nach ein paar Wochen in der Ecke.","image":"story.wunschinsel.6.1"},{"speaker":"tala","text":"An einen schönen Ausflug erinnere ich mich noch lange. Wie an unsere erste Fahrt mit dem Schiff!","image":"story.wunschinsel.6.2"},{"speaker":"talo","text":"Erlebnisse teilt man mit anderen. Und viele schöne Erlebnisse kosten kaum Geld.","image":"story.wunschinsel.6.3"}],"game":{"type":"choice","title":"Erinnerungs-Album","description":"Vergleiche ein neues Spielzeug mit einem gemeinsamen Ausflug und gestalte ein kleines Album schöner Erlebnisse.","task":"Gestalte mit Tala ihr Erinnerungs-Album. Was bleibt lange in Erinnerung?","rounds":[{"scene":[{"speaker":"tala","text":"Letztes Jahr habe ich ein neues Spielzeug bekommen und war mit allen am Leuchtturm picknicken."}],"question":"Woran erinnert sich Tala heute noch am liebsten?","options":[{"text":"An das Picknick am Leuchtturm","good":true,"reply":"Genau. Gemeinsame Erlebnisse bleiben oft lange in Erinnerung."},{"text":"An das neue Spielzeug","good":false,"reply":"Das Spielzeug liegt längst in der Ecke. Das Picknick erzählt Tala immer noch gern."}]},{"scene":[{"speaker":"talo","text":"Welches Bild kleben wir ins Album?"}],"question":"Such ein Bild aus.","options":[{"text":"Die Sandburg mit der ganzen Crew","good":true,"reply":"Schön! Daran erinnert ihr euch bestimmt noch lange."},{"text":"Die Nachtfahrt mit der Laterne","good":true,"reply":"Toll! Ein Abenteuer, das ihr zusammen erlebt habt."},{"text":"Das Gewitter, als alle zusammen im Schiff saßen","good":true,"reply":"Spannend! Auch das erzählt man sich noch lange."}]},{"scene":[{"speaker":"tala","text":"Was kostet eigentlich am wenigsten?"}],"question":"Was davon kostet oft wenig oder gar nichts?","options":[{"text":"Ein Ausflug an den Strand mit Freunden","good":true,"reply":"Genau. Schöne Erlebnisse müssen nicht teuer sein."},{"text":"Eine teure Spielkonsole","good":false,"reply":"Die kostet viel Geld. Ein Ausflug an den Strand oft gar nichts."}]}],"done":{"speaker":"tala","text":"Mein Album ist voller schöner Erlebnisse. Die bleiben länger als jedes Spielzeug."}},"estimate":{"speaker":"tala","question":"Was glaubst du: Woran erinnert sich Talo nach einem Jahr eher?","kind":"choice","options":["An ein Geschenk","An einen Ausflug"],"answer":1,"reveal":{"speaker":"talo","text":"An den Ausflug! Erlebnisse bleiben oft länger in Erinnerung als Dinge."}},"taps":[{"after":2,"kind":"drag","text":"Kleb das Foto ins Album.","symbol":"foto","done":"Eine schöne Erinnerung!"},{"after":3,"kind":"swipe","text":"Blätter eine Seite im Album um.","symbol":"buch","done":"Noch mehr schöne Erlebnisse."}],"summary":{"speaker":"tala","text":"Erlebnisse bleiben oft länger in Erinnerung als Dinge."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station6/q1')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Was bleibt oft länger in Erinnerung?', '["Ein Tag am See mit Freunden","Ein neues T-Shirt","Ein neues Spiel fürs Handy"]'::jsonb, 0, 'Gemeinsame Erlebnisse bleiben lange im Gedächtnis.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station6/q2')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Warum sind Erlebnisse oft besonders wertvoll?', '["Man teilt sie mit anderen und erinnert sich gern daran.","Weil sie immer teuer sind","Weil man sie später verkaufen kann"]'::jsonb, 0, 'Erinnerungen verbinden Menschen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station6/q3')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Was kostet oft kaum Geld und macht trotzdem Freude?', '["Ein Picknick im Park","Ein neues Handy","Eine Fernreise"]'::jsonb, 0, 'Viele schöne Erlebnisse kosten wenig.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station6/q4')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Was passiert oft mit neuen Spielsachen nach einiger Zeit?', '["Man spielt seltener damit.","Man spielt immer öfter damit.","Sie werden immer spannender."]'::jsonb, 0, 'Neues wird schnell normal.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station6/q5')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Wofür ist ein Erinnerungs-Album gut?', '["Um schöne Erlebnisse festzuhalten","Um zu zeigen, was etwas gekostet hat","Um Wunschlisten aufzuschreiben"]'::jsonb, 0, 'Ein Album hilft, sich an Schönes zu erinnern.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station6/q6')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Du hast 20 Taler: neues Spielzeug oder Ausflug mit Freunden. Was stimmt?', '["Beides ist in Ordnung, aber der Ausflug bleibt oft länger in Erinnerung.","Nur das Spielzeug ist vernünftig.","Nur der Ausflug ist richtig."]'::jsonb, 0, 'Es ist deine Entscheidung. Erlebnisse halten aber oft länger.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station7')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 70, 'game', true, 100, '{"title":"Meine Wunschliste","number":7,"place":"Wunschbrunnen","goal":"Eine gute Wunschliste hilft beim Planen","minutes":"7 bis 10 Min.","scene":[{"speaker":"tala","text":"Da ist der Wunschbrunnen! Und unten leuchtet das Kartenstück!"},{"speaker":"elsa","text":"Das Kartenstück erscheint nur, wenn man eine kluge Wunschliste hineinwirft.","name":"Elsa"},{"speaker":"tala","text":"Eine kluge Wunschliste? Ich schreibe einfach alles auf!"},{"speaker":"talo","text":"Klug heißt: mit Preisen und nach Wichtigkeit sortiert."}],"lesson":[{"speaker":"talo","text":"Schreib deine Wünsche auf und schätze, was sie ungefähr kosten.","image":"story.wunschinsel.7.1"},{"speaker":"tala","text":"Dann sortiere ich: Was ist mir am wichtigsten? Das kommt nach oben.","image":"story.wunschinsel.7.2"},{"speaker":"talo","text":"Für den wichtigsten Wunsch kannst du einen Wunschschatz anlegen und dafür sparen.","image":"story.wunschinsel.7.3"},{"speaker":"elsa","text":"Oh, eine kluge Liste! Seht nur, das Kartenstück steigt auf!","name":"Elsa","image":"story.wunschinsel.7.4"}],"game":{"type":"choice","title":"Wunschliste","description":"Schreibe eine Wunschliste mit Preisen, sortiere sie nach Wichtigkeit und übernimm einen Wunsch als Wunschschatz.","task":"Hilf Tala, eine kluge Wunschliste zu schreiben.","rounds":[{"scene":[{"speaker":"tala","text":"Ich schreibe einfach alles auf, was mir einfällt!"}],"question":"Was gehört auf eine kluge Wunschliste?","options":[{"text":"Der Wunsch und was er ungefähr kostet","good":true,"reply":"Genau. Mit dem Preis weißt du, wie lange du sparen musst."},{"text":"Nur die teuersten Dinge","good":false,"reply":"Auf eine Wunschliste gehört, was du dir wirklich wünschst, egal ob teuer oder günstig."}]},{"scene":[{"speaker":"talo","text":"Deine Liste ist lang. Wie bringst du Ordnung hinein?"}],"question":"Wie sortierst du die Liste?","options":[{"text":"Nach Wichtigkeit","good":true,"reply":"Richtig. Das Wichtigste steht oben, dafür sparst du zuerst."},{"text":"Nach Farben","good":false,"reply":"Farben sagen nichts darüber, was dir am wichtigsten ist."}]},{"scene":[{"speaker":"tala","text":"Auf meiner Liste stehen ein Fahrrad (am wichtigsten), ein Glitzerkompass und ein Comic."}],"question":"Wofür spart Tala zuerst?","options":[{"text":"Für das Fahrrad","good":true,"reply":"Genau. Das Wichtigste wird zuerst ein Wunschschatz in der Schatztruhe."},{"text":"Für den Glitzerkompass, weil er so glänzt","good":false,"reply":"Tala hat selbst gesagt: Das Fahrrad ist ihr am wichtigsten."}]}],"done":{"speaker":"talo","text":"Eine gute Wunschliste hilft beim Planen. In deiner Schatztruhe kannst du aus einem Wunsch einen Wunschschatz machen."}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie viel kostet deine ganze Wunschliste?","kind":"slider","min":0,"max":200,"step":10,"start":50,"unit":"Euro","reveal":{"speaker":"talo","text":"Rechne es gleich nach! Mit Preisen auf der Liste siehst du, was du dir leisten kannst und wofür du sparen musst."}},"taps":[{"after":2,"kind":"drag","text":"Zieh deinen wichtigsten Wunsch nach oben.","symbol":"liste","done":"Das Wichtigste steht jetzt oben."},{"after":3,"kind":"swipe","text":"Wirf die fertige Liste in den Brunnen.","symbol":"wellen","done":"Der Brunnen beginnt zu leuchten …"}],"summary":{"speaker":"talo","text":"Eine gute Wunschliste hilft beim Planen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station7/q1')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Was gehört auf eine kluge Wunschliste?', '["Wünsche mit ungefähren Preisen, sortiert nach Wichtigkeit","Alles aus der Werbung","Nur die teuersten Sachen"]'::jsonb, 0, 'So sieht man, was man sich leisten kann und was zuerst kommt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station7/q2')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Warum schreibt man die Preise dazu?', '["Damit man sieht, wie viel man sparen muss","Damit man das Teuerste zuerst kauft","Damit die Eltern alles bezahlen"]'::jsonb, 0, 'Mit Preisen kann man planen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station7/q3')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Welcher Wunsch kommt auf der Liste nach oben?', '["Der, der mir am wichtigsten ist","Der, der am teuersten ist","Der, den meine Freunde haben"]'::jsonb, 0, 'Die Reihenfolge zeigt deine Prioritäten.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station7/q4')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Was kannst du mit deinem wichtigsten Wunsch machen?', '["Einen Wunschschatz anlegen und dafür sparen","Ihn sofort kaufen, auch ohne genug Geld","Warten, bis ihn jemand schenkt"]'::jsonb, 0, 'Ein Wunschschatz macht aus einem Wunsch ein Ziel.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station7/q5')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Tala wünscht sich ein Fernrohr für 30 Taler und legt jede Woche 5 Taler zur Seite. Wie viele Wochen muss sie sparen?', '["6 Wochen","3 Wochen","30 Wochen"]'::jsonb, 0, '30 Taler geteilt durch 5 Taler pro Woche sind 6 Wochen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station7/q6')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Warum ist eine Wunschliste besser, als alles sofort zu kaufen?', '["Man denkt nach und gibt Geld für das Wichtigste aus.","Weil man dann mehr kaufen kann","Weil Wünsche dann billiger werden"]'::jsonb, 0, 'Planen hilft, das eigene Geld klug einzusetzen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station8')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 80, 'exam', true, 150, '{"title":"Abschlussprüfung","number":8,"place":"Wunschbrunnen","goal":"Alles von der Wunschinsel wiederholen, dazu zwei Fragen von früheren Inseln","minutes":"8 bis 10 Min.","scene":[{"speaker":"talo","text":"Letzte Prüfung auf der Wunschinsel. Ab 8 richtigen Antworten steigt das Kartenstück aus dem Brunnen."},{"speaker":"tala","text":"Ich wünsche mir … dass wir bestehen! Und das ist ein echter Wunsch, kein Glitzerkram."}],"summary":{"speaker":"tala","text":"Geschafft! Das Kartenstück ist unser. Auf zur nächsten Insel!"},"exam":{"show":8,"review":2,"pass":8}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q1')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was ist ein Bedürfnis?', '["Etwas, das man zum Leben braucht","Etwas, das gerade alle haben","Etwas, das man sich lange wünscht"]'::jsonb, 0, 'Essen, Trinken, Kleidung und ein Zuhause sind Bedürfnisse.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q2')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was ist ein Wunsch und kein Bedürfnis?', '["Eine neue Spielkonsole","Trinkwasser","Eine warme Jacke im Winter"]'::jsonb, 0, 'Eine Konsole macht Spaß, zum Leben braucht man sie nicht.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q3')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum ist es wichtig, Bedürfnisse und Wünsche zu unterscheiden?', '["Damit zuerst das Wichtige bezahlt wird","Damit man nie etwas Schönes kauft","Damit man nur noch Bedürfnisse kauft"]'::jsonb, 0, 'Wünsche sind in Ordnung, Bedürfnisse kommen zuerst.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q4')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Ist ein Handy ein Bedürfnis oder ein Wunsch?', '["Das kommt auf die Situation an.","Immer ein Bedürfnis wie Wasser","Immer nur ein Wunsch"]'::jsonb, 0, 'Manche Dinge liegen dazwischen.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q5')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Du hast 10 Taler und drei Wünsche für je 6 Taler. Was tust du?', '["Den wichtigsten auswählen","Alle drei kaufen","Zwei kaufen und den Rest leihen"]'::jsonb, 0, '10 Taler reichen nur für einen.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q6')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was heißt „Prioritäten setzen“?', '["Entscheiden, was am wichtigsten ist","Alles gleichzeitig machen","Immer das Billigste kaufen"]'::jsonb, 0, 'Wer Prioritäten setzt, gibt sein Geld für das Wichtigste aus.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q7')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Wenn du dich für einen Wunsch entscheidest, …', '["verzichtest du auf einen anderen.","bekommst du alle anderen gratis.","ist das Geld danach noch da."]'::jsonb, 0, 'Geld kann man nur einmal ausgeben.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q8')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was besagt die Warte-Regel?', '["Vor einem Kauf erst drüber schlafen","Immer sofort kaufen","Nur kaufen, was im Angebot ist"]'::jsonb, 0, 'Mit etwas Abstand entscheidet man besser.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q9')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum hilft Warten vor einem Kauf?', '["Man merkt, ob man es wirklich will.","Die Sachen werden beim Warten billiger.","Man bekommt dann mehr Taschengeld."]'::jsonb, 0, 'Viele Wünsche verschwinden nach ein paar Tagen von selbst.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q10')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Wie lange wartet man bei großen Wünschen?', '["Länger, zum Beispiel eine Woche","Eine Nacht, wie bei kleinen Wünschen","Mindestens ein ganzes Jahr"]'::jsonb, 0, 'Je teurer, desto länger lohnt sich das Überlegen.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q11')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Alle in deiner Klasse haben eine bestimmte Trinkflasche. Welche Frage hilft dir?', '["Brauche ich sie wirklich oder will ich nur dazugehören?","Wie bekomme ich zwei davon?","Wer hat die teuerste?"]'::jsonb, 0, 'Diese Frage hilft gegen Gruppendruck.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q12')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was ist Gruppendruck?', '["Wenn man etwas tut, weil andere es erwarten","Wenn eine Gruppe ein Foto macht","Wenn man in einer Gruppe besser lernt"]'::jsonb, 0, 'Gruppendruck kann zu Käufen führen, die man gar nicht will.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q13')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Wie kannst du auf Gruppendruck reagieren?', '["Ruhig sagen, dass du es nicht brauchst","Sofort alles nachkaufen","Es kaufen, aber niemandem zeigen"]'::jsonb, 0, 'Freundlich Nein sagen ist stark.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q14')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was stimmt über Geld und Glück?', '["Geld kann Sorgen nehmen, aber Freunde und Zeit machen auch glücklich.","Wer am meisten Geld hat, ist immer am glücklichsten.","Geld macht immer unglücklich."]'::jsonb, 0, 'Glück hat viele Quellen.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q15')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum hält die Freude über ein neues Spielzeug oft nicht lange?', '["Weil man sich schnell daran gewöhnt","Weil es meistens schnell kaputtgeht","Weil Eltern es wegräumen"]'::jsonb, 0, 'Neues wird schnell normal.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q16')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was macht Moritz glücklich, obwohl er wenig besitzt?', '["Seine Freunde und die Zeit mit ihnen","Seine vielen Sachen","Dass er nie arbeiten muss"]'::jsonb, 0, 'Moritz zeigt, dass Glück nicht vom Besitz abhängt.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q17')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was bleibt oft länger in Erinnerung?', '["Ein gemeinsamer Ausflug","Ein neues Paar Turnschuhe","Eine neue Hülle fürs Handy"]'::jsonb, 0, 'Erlebnisse teilt man und erinnert sich gern daran.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q18')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum können Erlebnisse mehr wert sein als Dinge?', '["Man erinnert sich gern daran und teilt sie mit anderen.","Weil Erlebnisse immer gratis sind","Weil Dinge immer kaputtgehen"]'::jsonb, 0, 'Erinnerungen bleiben, auch wenn Dinge alt werden.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q19')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was gehört auf eine gute Wunschliste?', '["Wünsche mit Preis, sortiert nach Wichtigkeit","Alles, was in der Werbung kommt","Nur Sachen von Freunden"]'::jsonb, 0, 'So sieht man, was man sich leisten kann.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/wunschinsel/station8/q20')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Du wünschst dir ein Fahrrad für 120 €. Du legst jeden Monat 15 € in deinen Wunschschatz. Wie lange dauert es?', '["8 Monate","12 Monate","15 Monate"]'::jsonb, 0, '120 € geteilt durch 15 € sind 8. Nach 8 Monaten ist genug im Wunschschatz.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

-- Ankerplatz 1: Die Kiste des Kapitäns
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/dive1')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 25, 'review_stop', true, 50, '{"title":"Die Kiste des Kapitäns","kind":"dive","number":1,"dive":{"game":"fish_swarm","questions":4,"wreck":{"scene":[{"speaker":"talo","text":"In diese Kiste passen nur fünf Dinge für eine lange Reise."},{"speaker":"tala","text":"Fünf Dinge? Ich hätte gern zwanzig!"}],"question":"Was gehört zuerst in die Kiste?","answers":["Wasser, Essen, eine warme Jacke, Verbandszeug und eine Karte","Fünf Comics","Eine Spielkonsole und vier Kuscheltiere"],"correct_index":0,"explanation":"Zuerst kommt, was man wirklich braucht. Wünsche dürfen mit, wenn noch Platz ist."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/wunschinsel/dive1/find')::uuid, 'wunschinsel-fund-1', 'wreck_item', 'Kapitänskiste', 'collectible.wunschinsel.1', md5('taleria:stage1/wunschinsel/dive1')::uuid, 31, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 2: Der Brief des Matrosen
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/dive2')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 45, 'review_stop', true, 50, '{"title":"Der Brief des Matrosen","kind":"dive","number":2,"dive":{"game":"pearls","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Ein Brief! Ein Matrose schreibt: Ich habe alles gekauft, was die anderen hatten. Jetzt ist mein Geld weg."},{"speaker":"talo","text":"Welchen Rat würdest du ihm geben?"}],"question":"Welcher Rat hilft dem Matrosen am meisten?","answers":["Vor jedem Kauf überlegen, ob er es selbst will oder nur, weil die anderen es haben.","Immer sofort kaufen, was die anderen haben.","Nie wieder etwas kaufen."],"correct_index":0,"explanation":"Gruppendruck ist stark. Eine Nacht drüber schlafen hilft, die eigenen Wünsche zu erkennen."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/wunschinsel/dive2/find')::uuid, 'wunschinsel-fund-2', 'wreck_item', 'Flaschenbrief', 'collectible.wunschinsel.2', md5('taleria:stage1/wunschinsel/dive2')::uuid, 32, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 3: Das Album der alten Crew
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/dive3')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 65, 'review_stop', true, 50, '{"title":"Das Album der alten Crew","kind":"dive","number":3,"dive":{"game":"treasure_chest","questions":4,"wreck":{"scene":[{"speaker":"talo","text":"Ein Fotoalbum der alten Crew und eine Kiste voller vergessener Sachen."},{"speaker":"tala","text":"In der Kiste liegt Spielzeug, das keiner mehr anschaut. Aber im Album lachen alle!"}],"question":"Was hat die alte Crew am glücklichsten gemacht?","answers":["Gemeinsame Abenteuer und Feste, an die sie sich gern erinnern","Die vielen Sachen in der Kiste","Möglichst viel Geld auszugeben"],"correct_index":0,"explanation":"Dinge sind schnell vergessen, gemeinsame Erlebnisse bleiben in Erinnerung."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/wunschinsel/dive3/find')::uuid, 'wunschinsel-fund-3', 'wreck_item', 'Altes Fotoalbum', 'collectible.wunschinsel.3', md5('taleria:stage1/wunschinsel/dive3')::uuid, 33, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

delete from public.quiz_questions q using public.stations s
where q.station_id = s.id and s.island_id = md5('taleria:stage1/wunschinsel')::uuid
  and q.id not in (md5('taleria:stage1/wunschinsel/sea1/q1')::uuid, md5('taleria:stage1/wunschinsel/sea1/q2')::uuid, md5('taleria:stage1/wunschinsel/sea1/q3')::uuid, md5('taleria:stage1/wunschinsel/sea1/q4')::uuid, md5('taleria:stage1/wunschinsel/sea1/q5')::uuid, md5('taleria:stage1/wunschinsel/sea1/q6')::uuid, md5('taleria:stage1/wunschinsel/sea2/q1')::uuid, md5('taleria:stage1/wunschinsel/sea2/q2')::uuid, md5('taleria:stage1/wunschinsel/sea2/q3')::uuid, md5('taleria:stage1/wunschinsel/sea2/q4')::uuid, md5('taleria:stage1/wunschinsel/sea2/q5')::uuid, md5('taleria:stage1/wunschinsel/sea2/q6')::uuid, md5('taleria:stage1/wunschinsel/station1/q1')::uuid, md5('taleria:stage1/wunschinsel/station1/q2')::uuid, md5('taleria:stage1/wunschinsel/station1/q3')::uuid, md5('taleria:stage1/wunschinsel/station1/q4')::uuid, md5('taleria:stage1/wunschinsel/station1/q5')::uuid, md5('taleria:stage1/wunschinsel/station1/q6')::uuid, md5('taleria:stage1/wunschinsel/station2/q1')::uuid, md5('taleria:stage1/wunschinsel/station2/q2')::uuid, md5('taleria:stage1/wunschinsel/station2/q3')::uuid, md5('taleria:stage1/wunschinsel/station2/q4')::uuid, md5('taleria:stage1/wunschinsel/station2/q5')::uuid, md5('taleria:stage1/wunschinsel/station2/q6')::uuid, md5('taleria:stage1/wunschinsel/station3/q1')::uuid, md5('taleria:stage1/wunschinsel/station3/q2')::uuid, md5('taleria:stage1/wunschinsel/station3/q3')::uuid, md5('taleria:stage1/wunschinsel/station3/q4')::uuid, md5('taleria:stage1/wunschinsel/station3/q5')::uuid, md5('taleria:stage1/wunschinsel/station3/q6')::uuid, md5('taleria:stage1/wunschinsel/station4/q1')::uuid, md5('taleria:stage1/wunschinsel/station4/q2')::uuid, md5('taleria:stage1/wunschinsel/station4/q3')::uuid, md5('taleria:stage1/wunschinsel/station4/q4')::uuid, md5('taleria:stage1/wunschinsel/station4/q5')::uuid, md5('taleria:stage1/wunschinsel/station4/q6')::uuid, md5('taleria:stage1/wunschinsel/station5/q1')::uuid, md5('taleria:stage1/wunschinsel/station5/q2')::uuid, md5('taleria:stage1/wunschinsel/station5/q3')::uuid, md5('taleria:stage1/wunschinsel/station5/q4')::uuid, md5('taleria:stage1/wunschinsel/station5/q5')::uuid, md5('taleria:stage1/wunschinsel/station5/q6')::uuid, md5('taleria:stage1/wunschinsel/station6/q1')::uuid, md5('taleria:stage1/wunschinsel/station6/q2')::uuid, md5('taleria:stage1/wunschinsel/station6/q3')::uuid, md5('taleria:stage1/wunschinsel/station6/q4')::uuid, md5('taleria:stage1/wunschinsel/station6/q5')::uuid, md5('taleria:stage1/wunschinsel/station6/q6')::uuid, md5('taleria:stage1/wunschinsel/station7/q1')::uuid, md5('taleria:stage1/wunschinsel/station7/q2')::uuid, md5('taleria:stage1/wunschinsel/station7/q3')::uuid, md5('taleria:stage1/wunschinsel/station7/q4')::uuid, md5('taleria:stage1/wunschinsel/station7/q5')::uuid, md5('taleria:stage1/wunschinsel/station7/q6')::uuid, md5('taleria:stage1/wunschinsel/station8/q1')::uuid, md5('taleria:stage1/wunschinsel/station8/q2')::uuid, md5('taleria:stage1/wunschinsel/station8/q3')::uuid, md5('taleria:stage1/wunschinsel/station8/q4')::uuid, md5('taleria:stage1/wunschinsel/station8/q5')::uuid, md5('taleria:stage1/wunschinsel/station8/q6')::uuid, md5('taleria:stage1/wunschinsel/station8/q7')::uuid, md5('taleria:stage1/wunschinsel/station8/q8')::uuid, md5('taleria:stage1/wunschinsel/station8/q9')::uuid, md5('taleria:stage1/wunschinsel/station8/q10')::uuid, md5('taleria:stage1/wunschinsel/station8/q11')::uuid, md5('taleria:stage1/wunschinsel/station8/q12')::uuid, md5('taleria:stage1/wunschinsel/station8/q13')::uuid, md5('taleria:stage1/wunschinsel/station8/q14')::uuid, md5('taleria:stage1/wunschinsel/station8/q15')::uuid, md5('taleria:stage1/wunschinsel/station8/q16')::uuid, md5('taleria:stage1/wunschinsel/station8/q17')::uuid, md5('taleria:stage1/wunschinsel/station8/q18')::uuid, md5('taleria:stage1/wunschinsel/station8/q19')::uuid, md5('taleria:stage1/wunschinsel/station8/q20')::uuid);

insert into public.badges (id, slug, kind, island_id, title, asset_key, sort_order, status)
values (md5('taleria:stage1/wunschinsel/badge')::uuid, 'wunschinsel', 'island', md5('taleria:stage1/wunschinsel')::uuid, 'Klarer Kompass', 'badge.wunschinsel', 3, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, sort_order = excluded.sort_order,
  status = excluded.status;

insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/wunschinsel/prompt1')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 'Was hast du dir mal sehr gewünscht und dann kaum benutzt?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/wunschinsel/prompt2')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 'Was war dein schönstes Erlebnis, das fast kein Geld gekostet hat?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/wunschinsel')::uuid and status <> 'draft';

-- 4. Spar-Insel, Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/spar-insel')::uuid, 'spar-insel', 1, 1, 4, 0.5, 0.765, 'main', 'Spar-Insel', '{"goal":"Das Kind weiß, warum man spart, legt einen echten Wunschschatz an, versteht, wie kleine Beträge wachsen, plant mit einem Sparplan und kennt sichere Orte für Geld.","learn":["Warum Sparen hilft, auch für Notfälle","Wie kleine Beträge mit der Zeit groß werden","Wie du mit einem Sparplan dein Ziel erreichst"],"access":"premium","arrival":{"video_key":"video.arrival.spar-insel","scene":[{"speaker":"tala","text":"Huch! Überall bunte Blätter auf dem Deck. Hier ist ja Herbst!"},{"speaker":"emma","text":"Willkommen auf der Spar-Insel! Entschuldigt, ich muss noch Nüsse in den Speicher tragen.","name":"Emma"},{"speaker":"gustav","text":"Warum sammeln? Es ist doch genug da! Kommt, wir machen Musik!","name":"Gustav"},{"speaker":"tala","text":"Hm. Bin ich eher wie Emma oder wie Gustav?"},{"speaker":"talo","text":"Schau, im großen Vorratsspeicher leuchtet das nächste Kartenstück."}]},"badge":"Vorratsmeister","real_life_task":{"title":"Erster Wunschschatz","text":"Legt gemeinsam einen echten Wunschschatz mit Sparplan an und besprecht, wie viel jede Woche in die Schatztruhe kommt."},"teaser":{"scene":[{"speaker":"talo","text":"Hinter dem Nebel liegt eine ruhige Bucht mit einem kleinen Kiosk."},{"speaker":"tala","text":"Ein Kiosk? Dann muss ich mein Taschengeld aber gut einteilen …"}],"next_slug":"taschengeld-bucht","next_title":"Taschengeld-Bucht"}}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Stopp auf See 1: Ottis Fischerboot
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/sea1')::uuid, md5('taleria:stage1/spar-insel')::uuid, 1, 'sea_stop', true, 30, '{"title":"Ottis Fischerboot","kind":"sea_stop","stop":{"type":"fischerboot","figure":"otti","index":1,"ship":"ship.fischer"},"scene":[{"speaker":"otti","text":"Ahoi! Ich will mir ein neues Netz kaufen. Aber ich wünsche mir auch einen Hut, eine Laterne und ein Boot in Rot!"},{"speaker":"tala","text":"Oh, das kenne ich. Auf der Wunschinsel haben wir gelernt, was zuerst kommt."}],"summary":{"speaker":"otti","text":"Erst das Netz, dann der Rest. Danke, Crew! Gute Fahrt zur Spar-Insel."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea1/q1')::uuid, md5('taleria:stage1/spar-insel/sea1')::uuid, 'Otti braucht ein Netz zum Fischen und wünscht sich einen Hut. Was kommt zuerst?', '["Das Netz, weil sie es zum Arbeiten braucht","Der Hut, weil er schöner ist","Beides gleichzeitig, egal wie teuer"]'::jsonb, 0, 'Erst das Nötige, dann das Schöne.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea1/q2')::uuid, md5('taleria:stage1/spar-insel/sea1')::uuid, 'Otti fragt: Woran erkenne ich ein Bedürfnis?', '["Ich brauche es zum Leben, wie Essen oder Kleidung.","Alle anderen haben es auch.","Ich wünsche es mir schon lange."]'::jsonb, 0, 'Essen, Trinken, Kleidung und ein Zuhause sind Bedürfnisse.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea1/q3')::uuid, md5('taleria:stage1/spar-insel/sea1')::uuid, 'Otti will sofort ein rotes Boot kaufen. Was hilft ihr bei der Entscheidung?', '["Eine Nacht oder eine Woche darüber schlafen","Sofort kaufen, bevor es weg ist","Die anderen Fischer fragen, was sie haben"]'::jsonb, 0, 'Die Warte-Regel zeigt, ob man den Wunsch wirklich will.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea1/q4')::uuid, md5('taleria:stage1/spar-insel/sea1')::uuid, 'Alle Fischer haben eine neue Laterne. Otti will deshalb auch eine. Wie nennt man das?', '["Gruppendruck","Sparen","Tauschen"]'::jsonb, 0, 'Wenn man etwas nur will, weil andere es haben, ist das Gruppendruck.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea1/q5')::uuid, md5('taleria:stage1/spar-insel/sea1')::uuid, 'Was macht nach einem Jahr meistens länger froh?', '["Ein schöner Ausflug mit Freunden","Ein neues Spielzeug, das bald in der Ecke liegt","Möglichst viele Dinge auf einmal"]'::jsonb, 0, 'Erlebnisse bleiben lange in Erinnerung.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea1/q6')::uuid, md5('taleria:stage1/spar-insel/sea1')::uuid, 'Otti hat 10 Taler. Das Netz kostet 7 Taler, der Hut 5 Taler. Was geht?', '["Das Netz kaufen, dann bleiben 3 Taler übrig.","Beides kaufen, das passt genau.","Nur den Hut kaufen und das Netz später."]'::jsonb, 0, '7 und 5 sind 12, mehr als 10. Das Netz ist wichtiger.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;

-- Stopp auf See 2: Tala hat etwas vergessen
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/sea2')::uuid, md5('taleria:stage1/spar-insel')::uuid, 2, 'sea_stop', true, 30, '{"title":"Tala hat etwas vergessen","kind":"sea_stop","stop":{"type":"tala_vergisst","figure":"tala","index":2},"scene":[{"speaker":"tala","text":"Oh nein! Was war noch mal die Wunschflasche? Und die Warte-Regel?"},{"speaker":"talo","text":"Kein Problem. Hilfst du Tala, sich zu erinnern?"}],"summary":{"speaker":"tala","text":"Jetzt weiß ich es wieder! Auf zur Spar-Insel!"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea2/q1')::uuid, md5('taleria:stage1/spar-insel/sea2')::uuid, 'Tala fragt: Wozu ist die Wunschflasche gut?', '["Man wartet ab, ob man den Wunsch später noch will.","Man bekommt den Wunsch sofort geschenkt.","Man wirft den Wunsch für immer weg."]'::jsonb, 0, 'Nach der Wartezeit fragt die App, ob man den Wunsch noch will.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea2/q2')::uuid, md5('taleria:stage1/spar-insel/sea2')::uuid, 'Tala fragt: Wie geht die Warte-Regel?', '["Vor einem Kauf eine Weile warten und dann noch einmal entscheiden","Immer sofort kaufen, bevor es weg ist","Nie etwas kaufen"]'::jsonb, 0, 'Viele Wünsche sind nach ein paar Tagen weg.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea2/q3')::uuid, md5('taleria:stage1/spar-insel/sea2')::uuid, 'Tala fragt: Was ist ein Wunsch und kein Bedürfnis?', '["Eine neue Spielkonsole","Trinkwasser","Eine warme Jacke im Winter"]'::jsonb, 0, 'Eine Konsole macht Spaß, zum Leben braucht man sie nicht.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea2/q4')::uuid, md5('taleria:stage1/spar-insel/sea2')::uuid, 'Tala fragt: Was tue ich, wenn mein Geld nicht für alles reicht?', '["Wichtiges zuerst und auf etwas verzichten","Einfach alles kaufen","Gar nichts mehr kaufen"]'::jsonb, 0, 'Prioritäten setzen heißt: das Wichtigste zuerst.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea2/q5')::uuid, md5('taleria:stage1/spar-insel/sea2')::uuid, 'Tala fragt: Macht Geld glücklich?', '["Es hilft gegen Sorgen, aber Freunde und Erlebnisse machen oft glücklicher.","Ja, je mehr Dinge, desto glücklicher","Nein, Geld ist immer schlecht"]'::jsonb, 0, 'Geld ist nützlich. Glück hängt aber an viel mehr.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/sea2/q6')::uuid, md5('taleria:stage1/spar-insel/sea2')::uuid, 'Tala fragt: Alle in meiner Klasse haben die gleiche Mütze. Muss ich sie auch haben?', '["Nein, ich überlege, ob ich sie selbst will.","Ja, sonst bin ich nicht dabei.","Ja, und gleich zwei davon."]'::jsonb, 0, 'Es zählt, was du selbst willst, nicht was alle haben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, status = excluded.status, beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station1')::uuid, md5('taleria:stage1/spar-insel')::uuid, 10, 'game', true, 100, '{"title":"Warum sparen?","number":1,"place":"Baumhaus-Dorf","goal":"Sparen bedeutet heute zurücklegen, um später etwas zu haben","minutes":"6 bis 9 Min.","scene":[{"speaker":"emma","text":"Willkommen im Baumhaus-Dorf! Hilfst du mir, die letzten Nüsse in den Speicher zu tragen?","name":"Emma"},{"speaker":"gustav","text":"Ach, Emma, sammel doch nicht so viel! Es liegen doch überall Nüsse herum.","name":"Gustav"},{"speaker":"tala","text":"Gustav hat recht, oder? Warum soll man etwas weglegen, wenn genug da ist?"},{"speaker":"talo","text":"Gute Frage, Tala. Warten wir mal ab, was im Winter passiert."}],"lesson":[{"speaker":"talo","text":"Im Herbst gibt es Nüsse im Überfluss. Emma isst nicht alle sofort, sie legt einen Teil zurück.","image":"story.spar-insel.1.1"},{"speaker":"tala","text":"Und dann kommt der Winter. Emma sitzt im Warmen bei ihrem Vorrat, und Gustav hat nichts mehr.","image":"story.spar-insel.1.2"},{"speaker":"talo","text":"Mit Geld ist es genauso. Sparen heißt: Heute etwas zurücklegen, damit man später etwas hat. Für einen großen Wunsch, für einen Notfall oder einfach für später.","image":"story.spar-insel.1.3"},{"speaker":"emma","text":"Ein kleiner Vorrat für schlechte Zeiten heißt Notgroschen. Wenn etwas kaputtgeht, muss man dann nicht gleich verzweifeln.","name":"Emma","image":"story.spar-insel.1.4"}],"game":{"type":"sort","title":"Wofür spart man?","description":"Ordne jeden Grund dem passenden Sparglas zu.","task":"Tippe auf eine Karte und dann auf das passende Glas.","items":[{"text":"Rollschuhe, die mehr kosten als das Taschengeld einer Woche","basket":0},{"text":"Ein neues Fahrradspiel für die Konsole","basket":0},{"text":"Die Brille ist zerbrochen und muss repariert werden","basket":1},{"text":"Der Fahrradreifen hat ein Loch","basket":1},{"text":"Das Geschenk für Omas Geburtstag in drei Monaten","basket":2},{"text":"Die Klassenfahrt im nächsten Jahr","basket":2},{"text":"Ein Fahrrad","basket":null,"hint":"Das kann ein großer Wunsch sein. Ist das alte Fahrrad kaputt und du brauchst es für den Schulweg, wird es fast zum Notfall."}],"baskets":["Für einen großen Wunsch","Für einen Notfall","Für später"],"done":{"speaker":"emma","text":"Ob Wunsch, Notfall oder später: Wer etwas zurückgelegt hat, kann sich darauf verlassen.","name":"Emma"}},"estimate":{"speaker":"emma","question":"Was glaubst du: Wie viele Nüsse brauche ich für einen ganzen Winter?","kind":"slider","min":0,"max":400,"step":20,"start":100,"unit":"Nüsse","answer":200,"reveal":{"speaker":"emma","text":"Ungefähr 200 Nüsse! Jeden Tag ein, zwei Nüsse, viele Wochen lang. So einen Vorrat sammelt man nicht an einem Tag."}},"taps":[{"after":1,"kind":"tap","text":"Sammle mit Emma Nüsse in den Beutel: Tippe dreimal.","symbol":"beutel","count":3,"done":"Drei Nüsse für den Vorrat!"},{"after":2,"kind":"flip","text":"Dreh die Tür des Speichers um. Was ist drin?","symbol":"tuer","back":"Ein voller Vorrat! Emma muss im Winter nicht hungern."}],"summary":{"speaker":"tala","text":"Ich glaube, ich will lieber wie Emma sein. Zumindest ein bisschen!"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station1/q1')::uuid, md5('taleria:stage1/spar-insel/station1')::uuid, 'Was bedeutet Sparen?', '["Heute etwas zurücklegen, um es später zu nutzen","Nie wieder etwas kaufen","Geld so schnell wie möglich ausgeben, bevor es weniger wird"]'::jsonb, 0, 'Gespartes Geld ist nicht weg. Es wartet auf später.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station1/q2')::uuid, md5('taleria:stage1/spar-insel/station1')::uuid, 'Warum hatte Gustav im Winter nichts mehr?', '["Er hat im Herbst alles sofort verbraucht.","Emma hat ihm alles weggenommen.","Im Herbst gab es keine Nüsse."]'::jsonb, 0, 'Im Herbst gab es genug. Gustav hat nur nichts zurückgelegt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station1/q3')::uuid, md5('taleria:stage1/spar-insel/station1')::uuid, 'Tala hat einen Notgroschen von 5 Talern. Ihr Fahrradschloss geht kaputt. Was ist klug?', '["Den Notgroschen für ein neues Schloss nehmen","Den Notgroschen für Süßigkeiten ausgeben, das Schloss kann warten","Nichts tun, einen Notgroschen darf man nie benutzen"]'::jsonb, 0, 'Genau für so etwas ist ein Notgroschen da: für unerwartete Ausgaben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station1/q4')::uuid, md5('taleria:stage1/spar-insel/station1')::uuid, 'Welcher Grund zum Sparen ist ein Notfall?', '["Die Fahrradkette ist gerissen.","Du wünschst dir ein neues Spiel.","Im Sommer ist ein Ausflug geplant."]'::jsonb, 0, 'Ein Notfall kommt unerwartet und muss schnell bezahlt werden.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station1/q5')::uuid, md5('taleria:stage1/spar-insel/station1')::uuid, 'Lohnt sich Sparen auch, wenn man gerade genug hat?', '["Ja, denn später kann es knapp werden.","Nein, wer genug hat, braucht nie zu sparen.","Nein, Sparen lohnt sich nur für Erwachsene."]'::jsonb, 0, 'Wie bei Emma: Gerade wenn genug da ist, kann man etwas zurücklegen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station1/q6')::uuid, md5('taleria:stage1/spar-insel/station1')::uuid, 'Tala bekommt 10 Taler und legt 3 davon in die Schatztruhe. Was hat sie gemacht?', '["Sie hat einen Teil gespart und kann den Rest ausgeben.","Sie hat 3 Taler verloren.","Sie darf jetzt gar nichts mehr kaufen."]'::jsonb, 0, 'Sparen heißt nicht alles oder nichts. Schon ein Teil hilft.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station1/q7')::uuid, md5('taleria:stage1/spar-insel/station1')::uuid, 'Wofür spart man nicht?', '["Um Geld wegzuschließen und nie zu benutzen","Für einen großen Wunsch","Für einen Notfall"]'::jsonb, 0, 'Gespartes Geld soll später helfen, für Wünsche, Notfälle oder später.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station2')::uuid, md5('taleria:stage1/spar-insel')::uuid, 20, 'game', true, 100, '{"title":"Mein erster Wunschschatz","number":2,"place":"Wunschschatz-Lichtung","goal":"Ein gutes Sparziel ist konkret","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Ich will auch sparen! Ich spare einfach … irgendwas. Irgendwann."},{"speaker":"emma","text":"Hm. Wofür denn? Und wie viel?","name":"Emma"},{"speaker":"tala","text":"Keine Ahnung. Ist das wichtig?"},{"speaker":"emma","text":"Sehr wichtig! Komm mit auf die Lichtung, ich zeige dir ein gutes Sparziel.","name":"Emma"}],"lesson":[{"speaker":"tala","text":"Ich wünsche mir rote Rollschuhe. Schon so lange!","image":"story.spar-insel.2.1"},{"speaker":"emma","text":"Ein gutes Sparziel hat drei Teile: Was willst du? Wie viel kostet es? Bis wann willst du es haben?","name":"Emma","image":"story.spar-insel.2.2"},{"speaker":"talo","text":"Rollschuhe, 40 Taler, bis zum Sommer. Das ist ein richtiger Wunschschatz!"},{"speaker":"tala","text":"Und damit ich ihn nicht vergesse, hänge ich ein Bild davon auf.","image":"story.spar-insel.2.3"},{"speaker":"emma","text":"In deiner Schatztruhe kannst du auch so einen Wunschschatz anlegen. Dann siehst du jeden Tag, wie nah du schon dran bist.","name":"Emma"}],"game":{"type":"choice","title":"Ein gutes Sparziel","description":"Hilf den Tieren, ein gutes Sparziel zu finden.","task":"Welches Sparziel ist klarer? Tippe auf deine Wahl.","rounds":[{"scene":[{"speaker":"tala","text":"Ich will für etwas Schönes sparen."}],"question":"Welches Ziel ist besser?","options":[{"text":"Rollschuhe für 40 Taler bis zum Sommer","good":true,"reply":"Genau! Tala weiß jetzt, was, wie viel und bis wann."},{"text":"Irgendwas Schönes, irgendwann","good":false,"reply":"Das ist zu ungenau. Wie soll Tala wissen, ob sie es geschafft hat?"}]},{"scene":[{"speaker":"gustav","text":"Ich spare für eine neue Geige. Wie viel sie kostet, weiß ich aber nicht.","name":"Gustav"}],"question":"Was fehlt Gustav noch?","options":[{"text":"Der Preis: Er muss herausfinden, was die Geige kostet.","good":true,"reply":"Richtig! Ohne Preis weiß Gustav nicht, wie viel er sparen muss."},{"text":"Gar nichts, er spart ja schon.","good":false,"reply":"Er weiß nicht, wie viel er braucht. So merkt er nie, ob es reicht."},{"text":"Eine zweite Geige als Ziel","good":false,"reply":"Ein Ziel nach dem anderen. Erst braucht Gustav den Preis der ersten."}]},{"scene":[{"speaker":"emma","text":"Ich will 60 Taler für eine Hängematte sparen.","name":"Emma"}],"question":"Was macht Emmas Ziel noch besser?","options":[{"text":"Ein Datum: bis zum Frühling","good":true,"reply":"Super! Mit einem Datum kann Emma planen, wie viel sie pro Woche braucht."},{"text":"Ein höherer Betrag, damit es schwerer wird","good":false,"reply":"Schwerer ist nicht besser. Das Ziel soll klar sein, nicht schwierig."},{"text":"Niemandem davon erzählen","good":false,"reply":"Es hilft eher, anderen vom Ziel zu erzählen. Dann bleibt man dran."}]}],"done":{"speaker":"emma","text":"Was, wie viel, bis wann: Mit diesen drei Fragen wird aus einem Wunsch ein Wunschschatz.","name":"Emma"}},"estimate":{"speaker":"emma","question":"Was glaubst du: Mit welchem Ziel schafft Tala es eher?","kind":"choice","options":["„Ich spare mal irgendwas.“","„Ich spare für Rollschuhe, 40 Taler, bis zum Sommer.“"],"answer":1,"reveal":{"speaker":"emma","text":"Mit dem klaren Ziel! Wer weiß, wofür, wie viel und bis wann, bleibt viel leichter dran."}},"taps":[{"after":1,"kind":"tap","text":"Such ein Bild für Talas Wunschschatz aus: Tippe auf den Bilderrahmen.","symbol":"foto","done":"Rote Rollschuhe! Das Bild erinnert Tala an ihr Ziel."},{"after":3,"kind":"drag","text":"Häng das Bild an den Ast.","symbol":"foto","done":"Jetzt hängt der Wunschschatz gut sichtbar am Baum."}],"summary":{"speaker":"tala","text":"Mein Wunschschatz: Rollschuhe, 40 Taler, bis zum Sommer! Leg deinen auch in der Schatztruhe an."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station2/q1')::uuid, md5('taleria:stage1/spar-insel/station2')::uuid, 'Tala sagt: Ich spare für Rollschuhe. Was fehlt noch für ein gutes Sparziel?', '["Wie viel sie kosten und bis wann sie sie haben will","In welchem Laden die anderen sie kaufen","Welche Farbe die Schnürsenkel haben"]'::jsonb, 0, 'Was, wie viel und bis wann: Erst mit Preis und Datum ist das Ziel klar.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station2/q2')::uuid, md5('taleria:stage1/spar-insel/station2')::uuid, 'Welches Sparziel ist am klarsten?', '["Ein Fußball für 20 Euro bis zu den Ferien","Etwas Tolles, wenn genug Geld da ist","Viel Geld, ganz schnell"]'::jsonb, 0, 'Was, wie viel und bis wann: Das hat nur der Fußball.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station2/q3')::uuid, md5('taleria:stage1/spar-insel/station2')::uuid, 'Dein Ziel kostet 50 Taler. Du hast schon 32. Wie viel fehlt noch?', '["18 Taler","28 Taler","82 Taler"]'::jsonb, 0, '50 minus 32 sind 18.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station2/q4')::uuid, md5('taleria:stage1/spar-insel/station2')::uuid, 'Warum hilft ein Bild von deinem Wunschschatz?', '["Es erinnert dich jeden Tag an dein Ziel.","Weil der Wunschschatz dadurch billiger wird","Weil man dann nicht mehr sparen muss"]'::jsonb, 0, 'Wer sein Ziel sieht, bleibt leichter dran.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station2/q5')::uuid, md5('taleria:stage1/spar-insel/station2')::uuid, 'Gustav weiß nicht, was seine Geige kostet. Was sollte er zuerst tun?', '["Den Preis herausfinden","Einfach alles ausgeben","Ein anderes Ziel nehmen"]'::jsonb, 0, 'Ohne Preis weiß man nicht, wie viel man sparen muss.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station2/q6')::uuid, md5('taleria:stage1/spar-insel/station2')::uuid, 'Tala hat 25 Taler. Die Rollschuhe kosten 40 Taler. Wie viel fehlt?', '["15 Taler","25 Taler","65 Taler"]'::jsonb, 0, '40 minus 25 sind 15.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station2/q7')::uuid, md5('taleria:stage1/spar-insel/station2')::uuid, 'Wo kannst du in Taleria deinen Wunschschatz anlegen?', '["In der Schatztruhe","Auf der Karte","Bei den Orden"]'::jsonb, 0, 'In der Schatztruhe siehst du, wie viel dir noch fehlt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station3')::uuid, md5('taleria:stage1/spar-insel')::uuid, 30, 'game', true, 100, '{"title":"Kleine Beträge werden groß","number":3,"place":"Nussturm","goal":"Auch kleine Beträge werden mit der Zeit viel","minutes":"6 bis 9 Min.","scene":[{"speaker":"emma","text":"Jeden Tag lege ich eine einzige Nuss auf meinen Turm.","name":"Emma"},{"speaker":"gustav","text":"Eine Nuss? Haha! Das bringt doch nichts.","name":"Gustav"},{"speaker":"tala","text":"Stimmt schon, eine Nuss ist wirklich wenig."},{"speaker":"emma","text":"Wartet nur ab.","name":"Emma"}],"lesson":[{"speaker":"emma","text":"Eine Nuss am Tag sieht nach nichts aus.","name":"Emma","image":"story.spar-insel.3.1"},{"speaker":"tala","text":"Aber nach vielen Wochen ist der Turm höher als die Bäume!","image":"story.spar-insel.3.2"},{"speaker":"talo","text":"Mit Geld geht das genauso. Wer jeden Tag 50 Cent zur Seite legt, hat nach einer Woche 3,50 Euro.","image":"drawing:coins_week"},{"speaker":"talo","text":"Nach einem Monat sind es schon etwa 15 Euro. Darum sagt man: Kleinvieh macht auch Mist."}],"game":{"type":"number","title":"Der Nussturm wächst","description":"Rechne aus, wie viel mit der Zeit zusammenkommt.","task":"Tippe deine Antwort als Zahl ein.","rounds":[{"question":"Emma legt jeden Tag 2 Nüsse auf den Turm. Wie viele Nüsse sind es nach einer Woche?","amount":14,"unit":"Nüsse","hint":"Eine Woche hat 7 Tage.","explanation":"7 Tage mal 2 Nüsse sind 14 Nüsse."},{"question":"Tala legt jede Woche 3 Taler in ihre Schatztruhe. Wie viele Taler hat sie nach 4 Wochen?","amount":12,"unit":"Taler","hint":"Rechne 4 mal 3.","explanation":"4 Wochen mal 3 Taler sind 12 Taler."},{"question":"Gustav kauft jeden Tag eine Limo für 1 Taler. Wie viele Taler könnte er in 30 Tagen sparen, wenn er darauf verzichtet?","amount":30,"unit":"Taler","hint":"Ein Taler an jedem der 30 Tage.","explanation":"30 Tage mal 1 Taler sind 30 Taler. Kleine Ausgaben summieren sich auch."}],"done":{"speaker":"gustav","text":"Okay, okay. Eine Nuss ist doch nicht nichts.","name":"Gustav"}},"estimate":{"speaker":"talo","question":"Was glaubst du: Wie viele Euro hat man nach einem Jahr, wenn man jeden Tag 50 Cent zur Seite legt?","kind":"slider","min":0,"max":400,"step":10,"start":50,"unit":"Euro","answer":180,"reveal":{"speaker":"talo","text":"Über 180 Euro! Jeden Tag nur 50 Cent, aber ein ganzes Jahr lang. Kleine Beträge werden mit der Zeit groß."}},"taps":[{"after":1,"kind":"tap","text":"Leg jeden Tag eine Münze auf den Turm: Tippe dreimal.","symbol":"muenze","count":3,"done":"Drei Tage, drei Münzen. Der Turm wächst!"},{"after":2,"kind":"flip","text":"Blättere im Kalender viele Wochen weiter.","symbol":"kalender","back":"Viele Wochen später: Aus einzelnen Nüssen ist ein riesiger Turm geworden."}],"summary":{"speaker":"emma","text":"Kleinvieh macht auch Mist: Auch wenig wird viel, wenn man dranbleibt.","name":"Emma"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station3/q1')::uuid, md5('taleria:stage1/spar-insel/station3')::uuid, 'Emmas Turm wächst jeden Tag nur um eine Nuss. Warum wird er trotzdem riesig?', '["Weil viele kleine Schritte über lange Zeit viel ergeben","Weil die Nüsse über Nacht wachsen","Weil Gustav heimlich Nüsse dazulegt"]'::jsonb, 0, 'Kleinvieh macht auch Mist: Regelmäßig ein bisschen wird viel.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station3/q2')::uuid, md5('taleria:stage1/spar-insel/station3')::uuid, 'Du legst jeden Tag 50 Cent zur Seite. Wie viel hast du nach zwei Wochen?', '["7 Euro","1 Euro","14 Euro"]'::jsonb, 0, 'Zwei Wochen sind 14 Tage. 14 mal 50 Cent sind 700 Cent, also 7 Euro.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station3/q3')::uuid, md5('taleria:stage1/spar-insel/station3')::uuid, 'Du sparst jede Woche 4 Taler. Wie viel hast du nach 5 Wochen?', '["20 Taler","9 Taler","45 Taler"]'::jsonb, 0, '5 mal 4 sind 20.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station3/q4')::uuid, md5('taleria:stage1/spar-insel/station3')::uuid, 'Gustav kauft jeden Tag ein Bonbon für 10 Cent. Wie viel gibt er in 30 Tagen aus?', '["3 Euro","30 Cent","10 Euro"]'::jsonb, 0, '30 mal 10 Cent sind 300 Cent, also 3 Euro. Auch kleine Ausgaben werden viel.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station3/q5')::uuid, md5('taleria:stage1/spar-insel/station3')::uuid, 'Was ist wichtiger, damit kleine Beträge groß werden?', '["Dass man regelmäßig und lange dranbleibt","Dass man einmal ganz viel auf einmal spart","Dass man das Geld oft zählt"]'::jsonb, 0, 'Die Zeit macht aus wenig viel.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station3/q6')::uuid, md5('taleria:stage1/spar-insel/station3')::uuid, 'Emma legt jeden Tag 1 Nuss auf den Turm. Wie viele Nüsse hat sie nach 3 Wochen?', '["21 Nüsse","3 Nüsse","10 Nüsse"]'::jsonb, 0, '3 Wochen sind 21 Tage, jeden Tag eine Nuss.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station3/q7')::uuid, md5('taleria:stage1/spar-insel/station3')::uuid, 'Tala will jeden Tag nur 20 Cent sparen. Was sagst du ihr?', '["Gute Idee, auch 20 Cent jeden Tag werden mit der Zeit viel.","Lass es, so wenig bringt nichts.","Spar lieber gar nicht, bis du mehr hast."]'::jsonb, 0, 'Jeder kleine Betrag hilft, wenn man dranbleibt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station4')::uuid, md5('taleria:stage1/spar-insel')::uuid, 40, 'game', true, 100, '{"title":"Geduld lohnt sich","number":4,"place":"Geduldsbank","goal":"Wer warten kann, bekommt oft mehr","minutes":"6 bis 9 Min.","scene":[{"speaker":"emma","text":"Setzt euch auf die Geduldsbank. Ich habe ein Angebot für euch.","name":"Emma"},{"speaker":"emma","text":"Ihr bekommt jetzt eine Nuss. Oder ihr wartet bis morgen und bekommt drei.","name":"Emma"},{"speaker":"gustav","text":"Jetzt! Sofort! Ich habe Hunger.","name":"Gustav"},{"speaker":"tala","text":"Hmm. Drei sind mehr. Aber morgen ist so weit weg …"}],"lesson":[{"speaker":"emma","text":"Eine Nuss jetzt oder drei morgen: Was nimmst du?","name":"Emma","image":"story.spar-insel.4.1"},{"speaker":"tala","text":"Gustav hat seine Nuss sofort gegessen. Ich warte. Das ist ganz schön schwer!","image":"story.spar-insel.4.2"},{"speaker":"tala","text":"Am nächsten Morgen habe ich drei Nüsse. Warten hat sich gelohnt!","image":"story.spar-insel.4.3"},{"speaker":"talo","text":"Wer warten kann, bekommt oft mehr. Beim Sparen ist das genauso: Erst sammeln, dann kaufen."},{"speaker":"emma","text":"Ein Trick für die Geduld: Schau dir an, wie viel du schon hast, statt an das zu denken, was du jetzt haben könntest.","name":"Emma"}],"game":{"type":"choice","title":"Jetzt oder später?","description":"Triff Entscheidungen und sieh, was Warten bringt.","task":"Was würdest du tun? Tippe auf deine Wahl.","rounds":[{"scene":[{"speaker":"emma","text":"Ein kleiner Kuchen jetzt oder ein großer am Sonntag?","name":"Emma"}],"question":"Was ist klug, wenn du nicht gerade Hunger hast?","options":[{"text":"Bis Sonntag warten und den großen nehmen","good":true,"reply":"Ein paar Tage Geduld, und du bekommst viel mehr."},{"text":"Sofort den kleinen nehmen","good":false,"reply":"Das geht natürlich. Aber wenn du warten kannst, bekommst du mehr."}]},{"scene":[{"speaker":"tala","text":"Ich habe 8 Taler. Am Kiosk gibt es jetzt Bonbons. In zwei Wochen habe ich genug für ein Buch, das ich mir wirklich wünsche."}],"question":"Was soll Tala tun?","options":[{"text":"Weitersparen und in zwei Wochen das Buch kaufen","good":true,"reply":"Genau! Die Bonbons sind schnell weg, das Buch hat sie lange."},{"text":"Die Bonbons kaufen und neu anfangen","good":false,"reply":"Dann fängt Tala wieder bei null an, und das Buch rückt weit weg."},{"text":"Ein paar Bonbons kaufen und den Rest sparen","good":true,"reply":"Auch das geht! Ein kleiner Teil für jetzt, der größere für das Buch. Es dauert dann nur etwas länger."}]},{"scene":[{"speaker":"gustav","text":"Ich will eine neue Geige. Aber es dauert noch so lange! Ich gebe auf.","name":"Gustav"}],"question":"Was hilft Gustav, geduldig zu bleiben?","options":[{"text":"Jede Woche ansehen, wie viel er schon gespart hat","good":true,"reply":"Wer sieht, dass es vorangeht, bleibt dran."},{"text":"Jeden Tag in den Laden gehen und die Geige anschauen","good":false,"reply":"Das macht das Warten oft schwerer. Besser ist es, den eigenen Fortschritt zu sehen."},{"text":"Das Ziel vergessen","good":false,"reply":"Wer das Ziel vergisst, gibt das Geld schnell für anderes aus."}]}],"done":{"speaker":"emma","text":"Geduld ist wie ein Muskel. Je öfter du wartest, desto leichter wird es.","name":"Emma"}},"estimate":{"speaker":"emma","question":"Was glaubst du: Wie viele Nüsse bekommt Tala, wenn sie bis morgen wartet?","kind":"wheel","min":1,"max":10,"start":1,"unit":"Nüsse","unit_one":"Nuss","answer":3,"reveal":{"speaker":"emma","text":"Drei Nüsse! Dreimal so viel, nur weil sie eine Nacht gewartet hat."}},"taps":[{"after":1,"kind":"tap","text":"Drück mit Tala den „Warten“-Knopf.","symbol":"hand","done":"Tala wartet. Das Körbchen mit drei Nüssen bleibt für sie stehen."},{"after":2,"kind":"flip","text":"Dreh den Kalender auf morgen.","symbol":"kalender","back":"Guten Morgen! Drei Nüsse warten auf Tala."}],"summary":{"speaker":"tala","text":"Warten ist schwer, aber drei Nüsse sind besser als eine!"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station4/q1')::uuid, md5('taleria:stage1/spar-insel/station4')::uuid, 'Gustav nimmt eine Nuss sofort, Tala wartet und bekommt morgen drei. Wie viele Nüsse hat Tala mehr?', '["2 Nüsse","3 Nüsse","1 Nuss"]'::jsonb, 0, '3 minus 1 sind 2. Warten hat sich gelohnt.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station4/q2')::uuid, md5('taleria:stage1/spar-insel/station4')::uuid, 'Tala muss noch 4 Wochen sparen und wird ungeduldig. Was hilft ihr?', '["Jede Woche ansehen, wie die Schatztruhe voller wird","Jeden Tag im Schaufenster die Rollschuhe anschauen","Aufhören und etwas anderes kaufen"]'::jsonb, 0, 'Wer sieht, dass es vorangeht, bleibt dran.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station4/q3')::uuid, md5('taleria:stage1/spar-insel/station4')::uuid, 'Warum ist Warten oft so schwer?', '["Weil man das Schöne am liebsten sofort hätte","Weil Warten verboten ist","Weil Gespartes jeden Tag weniger wird"]'::jsonb, 0, 'Das ist ganz normal. Mit Übung wird es leichter.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station4/q4')::uuid, md5('taleria:stage1/spar-insel/station4')::uuid, 'Tala hat 8 von 12 Talern für ein Buch. Am Kiosk gibt es Bonbons für 3 Taler. Was passiert, wenn sie die Bonbons kauft?', '["Ihr fehlen dann wieder 7 Taler für das Buch.","Das Buch wird billiger.","Sie hat dann sofort genug für das Buch."]'::jsonb, 0, '8 minus 3 sind 5. Bis 12 fehlen dann 7 Taler.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station4/q5')::uuid, md5('taleria:stage1/spar-insel/station4')::uuid, 'Gustav will aufgeben, weil das Sparen so lange dauert. Was rätst du ihm?', '["Kleine Zwischenziele feiern, zum Beispiel die Hälfte","Alles sofort ausgeben","Nie wieder etwas sparen"]'::jsonb, 0, 'Zwischenziele machen den langen Weg kürzer.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station4/q6')::uuid, md5('taleria:stage1/spar-insel/station4')::uuid, 'Wann ist es in Ordnung, nicht zu warten?', '["Wenn man etwas wirklich jetzt braucht, zum Beispiel etwas zu essen bei Hunger","Immer, Warten lohnt sich nie","Nie, man muss immer warten"]'::jsonb, 0, 'Geduld ist gut, aber Bedürfnisse gehen vor.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station4/q7')::uuid, md5('taleria:stage1/spar-insel/station4')::uuid, 'Emma sagt: Geduld ist wie ein Muskel. Was meint sie?', '["Je öfter man übt zu warten, desto leichter wird es.","Wer geduldig ist, wird stärker.","Geduld bekommt man nur beim Sport."]'::jsonb, 0, 'Geduld kann man üben, wie beim Training.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station5')::uuid, md5('taleria:stage1/spar-insel')::uuid, 50, 'game', true, 100, '{"title":"Einen Sparplan aufstellen","number":5,"place":"Planungs-Hütte","goal":"Ein Sparplan zeigt, wann man das Ziel erreicht","minutes":"6 bis 9 Min.","scene":[{"speaker":"emma","text":"In meiner Planungs-Hütte schreibe ich auf, wann ich wie viel spare.","name":"Emma"},{"speaker":"tala","text":"Ich spare für Rollschuhe. Aber wann habe ich genug?"},{"speaker":"emma","text":"Das rechnen wir aus. Mit einem Sparplan!","name":"Emma"}],"lesson":[{"speaker":"emma","text":"Ein Sparplan beantwortet eine Frage: Wann habe ich mein Ziel erreicht?","name":"Emma","image":"story.spar-insel.5.1"},{"speaker":"talo","text":"Das Ziel sind 30 Taler. Jede Woche kommen 5 Taler dazu. Nach 6 Wochen ist es geschafft.","image":"drawing:savings_plan"},{"speaker":"tala","text":"Jede Woche male ich ein Kästchen aus. Das erste ist schon fertig!","image":"story.spar-insel.5.3"},{"speaker":"emma","text":"Und wenn es schneller gehen soll? Dann legst du mehr pro Woche zurück oder wählst ein kleineres Ziel.","name":"Emma"}],"game":{"type":"number","title":"Sparplan-Rechner","description":"Rechne aus, wie lange das Sparen dauert.","task":"Tippe deine Antwort als Zahl ein.","rounds":[{"question":"Tala will 40 Taler sparen und legt jede Woche 5 Taler zurück. Wie viele Wochen dauert es?","amount":8,"unit":"Wochen","hint":"Wie oft passt 5 in 40?","explanation":"40 geteilt durch 5 sind 8. Nach 8 Wochen hat Tala ihre Rollschuhe."},{"question":"Gustav will 24 Taler sparen und legt jede Woche 4 Taler zurück. Wie viele Wochen dauert es?","amount":6,"unit":"Wochen","hint":"Rechne 24 geteilt durch 4.","explanation":"24 geteilt durch 4 sind 6 Wochen."},{"question":"Emma will in 5 Wochen 50 Taler haben. Wie viele Taler muss sie jede Woche zurücklegen?","amount":10,"unit":"Taler","hint":"Teile das Ziel durch die Zahl der Wochen.","explanation":"50 geteilt durch 5 sind 10 Taler pro Woche."}],"done":{"speaker":"emma","text":"Mit einem Sparplan weißt du immer, wann du am Ziel bist.","name":"Emma"}},"estimate":{"speaker":"emma","question":"Was glaubst du: Wie viele Wochen braucht man für 30 Taler, wenn man jede Woche 5 Taler spart?","kind":"wheel","min":1,"max":20,"start":1,"unit":"Wochen","unit_one":"Woche","answer":6,"reveal":{"speaker":"emma","text":"Sechs Wochen! 6 mal 5 Taler sind 30 Taler."}},"taps":[{"after":1,"kind":"tap","text":"Füll mit Emma die ersten Wochenkästchen aus: Tippe zweimal.","symbol":"liste","count":2,"done":"Zwei Wochen geschafft, vier liegen noch vor Tala."},{"after":2,"kind":"tap","text":"Stempel den Sparplan ab.","symbol":"stempel","done":"Abgestempelt! Der Plan gilt."}],"summary":{"speaker":"tala","text":"Mein Plan: 5 Taler pro Woche, in 8 Wochen habe ich die Rollschuhe!"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station5/q1')::uuid, md5('taleria:stage1/spar-insel/station5')::uuid, 'Wozu ist ein Sparplan gut?', '["Man weiß, wann man sein Ziel erreicht.","Damit man nie wieder etwas ausgibt","Damit das Ziel billiger wird"]'::jsonb, 0, 'Ein Sparplan sagt: so viel pro Woche, so lange bis zum Ziel.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station5/q2')::uuid, md5('taleria:stage1/spar-insel/station5')::uuid, 'Du willst 36 Taler sparen und legst 6 pro Woche zurück. Wie lange dauert es?', '["6 Wochen","5 Wochen","30 Wochen"]'::jsonb, 0, '36 geteilt durch 6 sind 6.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station5/q3')::uuid, md5('taleria:stage1/spar-insel/station5')::uuid, 'Du willst schneller am Ziel sein. Was hilft?', '["Jede Woche etwas mehr zurücklegen","Seltener in die Schatztruhe schauen","Den Sparplan wegwerfen"]'::jsonb, 0, 'Mehr pro Woche heißt: weniger Wochen bis zum Ziel.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station5/q4')::uuid, md5('taleria:stage1/spar-insel/station5')::uuid, 'Du bekommst zum Geburtstag 10 Euro geschenkt. Was ist klug für deinen Sparplan?', '["Einen Teil davon in die Schatztruhe legen","Alles sofort ausgeben","Das Geld verstecken und vergessen"]'::jsonb, 0, 'So kommst du deinem Ziel schneller näher.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station5/q5')::uuid, md5('taleria:stage1/spar-insel/station5')::uuid, 'Tala will 12 Euro sparen und legt jede Woche 1,50 Euro zurück. Wie viele Wochen braucht sie?', '["8 Wochen","12 Wochen","6 Wochen"]'::jsonb, 0, '1,50 Euro mal 8 sind 12 Euro.', null, 'draft', '{"question":"Tala will 12 Euro sparen und legt jede Woche 2 Euro zurück. Wie viele Wochen braucht sie?","answers":["6 Wochen","12 Wochen","4 Wochen"],"correct_index":0,"explanation":"12 geteilt durch 2 sind 6 Wochen."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station5/q6')::uuid, md5('taleria:stage1/spar-insel/station5')::uuid, 'Emma will in 4 Wochen 20 Taler haben. Wie viel muss sie pro Woche sparen?', '["5 Taler","4 Taler","16 Taler"]'::jsonb, 0, '20 geteilt durch 4 sind 5.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station5/q7')::uuid, md5('taleria:stage1/spar-insel/station5')::uuid, 'In einer Woche hat Tala nichts gespart. Was macht sie jetzt am besten?', '["In der nächsten Woche einfach weitermachen","Den ganzen Plan aufgeben","Alles Gesparte ausgeben"]'::jsonb, 0, 'Ein Plan darf auch mal holpern. Wichtig ist, dranzubleiben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station6')::uuid, md5('taleria:stage1/spar-insel')::uuid, 60, 'game', true, 100, '{"title":"Sparschwein, Spardose, Konto","number":6,"place":"Schatzkammer","goal":"Es gibt verschiedene Orte zum Sparen, mit Vor- und Nachteilen","minutes":"6 bis 9 Min.","scene":[{"speaker":"gustav","text":"Ich habe jetzt auch angefangen zu sparen! Meine Münzen sind … ähm … überall.","name":"Gustav"},{"speaker":"emma","text":"Überall? Dann komm mit in die Schatzkammer. Gespartes braucht einen guten Platz.","name":"Emma"}],"lesson":[{"speaker":"emma","text":"Es gibt verschiedene Orte für Gespartes: das Sparschwein, die Spardose und das Konto.","name":"Emma","image":"story.spar-insel.6.1"},{"speaker":"tala","text":"Mein Sparschwein mag ich am liebsten. Man hört und sieht, wie das Geld wächst!","image":"story.spar-insel.6.2"},{"speaker":"talo","text":"Aber Bargeld kann verloren gehen. So wie bei Gustav, der seine Münzen überall versteckt hat.","image":"story.spar-insel.6.3"},{"speaker":"emma","text":"Auf einem Konto ist das Geld sicherer aufbewahrt. Wie ein Konto funktioniert, lernt ihr später auf der Bank-Insel.","name":"Emma","image":"story.spar-insel.6.4"}],"game":{"type":"sort","title":"Wo liegt mein Geld gut?","description":"Ordne jeden Satz dem passenden Ort zu.","task":"Tippe auf eine Karte und dann auf den passenden Ort.","items":[{"text":"Man hört, wie die Münzen klimpern","basket":0},{"text":"Steht zu Hause im Regal","basket":0},{"text":"Geht nicht verloren, auch wenn etwas zu Hause passiert","basket":1},{"text":"Die Eltern helfen, es bei der Bank einzurichten","basket":1},{"text":"Man kann das Geld anfassen und zählen","basket":0},{"text":"Für größere Beträge, die lange liegen bleiben","basket":1},{"text":"Ein fester Platz für das Gesparte","basket":null,"hint":"Das gilt für beide! Wichtig ist, dass Gespartes nicht überall verteilt ist."}],"baskets":["Sparschwein oder Spardose","Konto bei der Bank"],"done":{"speaker":"emma","text":"Beides hat Vorteile. Hauptsache, dein Geld hat einen festen Platz.","name":"Emma"}},"estimate":{"speaker":"emma","question":"Was glaubst du: Wo ist Geld am sichersten aufbewahrt?","kind":"choice","options":["Unter dem Kopfkissen","Im Sparschwein","Auf einem Konto bei der Bank"],"answer":2,"reveal":{"speaker":"emma","text":"Auf dem Konto! Dort kann es nicht verloren gehen oder gestohlen werden. Das Sparschwein ist aber auch ein guter Anfang."}},"taps":[{"after":2,"kind":"tap","text":"Schüttel Talas Sparschwein: Tippe dreimal.","symbol":"muenze","count":3,"done":"Klimper, klimper! Das klingt nach einem guten Anfang."},{"after":3,"kind":"flip","text":"Dreh den Schlüssel der Schatzkammer um.","symbol":"schluessel","back":"Alles an einem sicheren Platz. So geht nichts verloren."}],"summary":{"speaker":"gustav","text":"Ich sammle meine Münzen jetzt alle an einem Ort. Versprochen!","name":"Gustav"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station6/q1')::uuid, md5('taleria:stage1/spar-insel/station6')::uuid, 'Talo und Tala vergleichen Sparschwein und Konto. Welcher Satz stimmt?', '["Auf dem Konto ist das Geld sicherer, im Sparschwein sieht man es wachsen.","Im Sparschwein ist das Geld sicherer als auf dem Konto.","Auf dem Konto hört man jede Münze klimpern."]'::jsonb, 0, 'Beides hat Vorteile: Sicherheit auf dem Konto, Anfassen beim Sparschwein.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station6/q2')::uuid, md5('taleria:stage1/spar-insel/station6')::uuid, 'Warum ist ein Sparschwein gut für den Anfang?', '["Man kann zusehen, wie das Gesparte mehr wird.","Es macht das Geld von allein mehr.","Niemand kann es jemals öffnen."]'::jsonb, 0, 'Sehen und Hören macht Mut zum Weitersparen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station6/q3')::uuid, md5('taleria:stage1/spar-insel/station6')::uuid, 'Wo liegt das Kleingeld für den Kiosk morgen gut?', '["Im Geldbeutel, an einem festen Platz","Für viele Jahre fest auf dem Konto","Verteilt in verschiedenen Jackentaschen"]'::jsonb, 0, 'Geld, das man bald ausgibt, darf griffbereit sein, aber an einem festen Ort.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station6/q4')::uuid, md5('taleria:stage1/spar-insel/station6')::uuid, 'Wer hilft Kindern, ein Konto bei der Bank einzurichten?', '["Die Eltern","Niemand, das macht man allein","Die Freunde aus der Klasse"]'::jsonb, 0, 'Für ein Konto braucht man als Kind die Eltern.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station6/q5')::uuid, md5('taleria:stage1/spar-insel/station6')::uuid, 'Gustav hat seine Münzen in einem Schuh, unter einem Stein und im Geigenkasten. Was rätst du ihm?', '["Alles an einem festen Ort sammeln","Noch mehr Verstecke suchen","Alles sofort ausgeben"]'::jsonb, 0, 'So weiß er immer, wie viel er hat, und nichts geht verloren.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station6/q6')::uuid, md5('taleria:stage1/spar-insel/station6')::uuid, 'Für welches Geld passt ein Konto besonders gut?', '["Für größere Beträge, die lange liegen bleiben","Für das Kleingeld für den Kiosk heute","Für Geld, das man morgen ausgeben will"]'::jsonb, 0, 'Was lange liegen bleibt, ist auf dem Konto gut aufgehoben.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station6/q7')::uuid, md5('taleria:stage1/spar-insel/station6')::uuid, 'Tala hat 20 Euro im Sparschwein. Was ist dabei ein Risiko?', '["Das Sparschwein kann herunterfallen, verloren gehen oder gestohlen werden.","Das Geld wird im Sparschwein von allein weniger.","Im Sparschwein darf man nur Münzen haben."]'::jsonb, 0, 'Bargeld zu Hause kann verloren gehen. Darum kommen größere Beträge gern auf ein Konto.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station7')::uuid, md5('taleria:stage1/spar-insel')::uuid, 70, 'game', true, 100, '{"title":"Schatztruhen-Challenge","number":7,"place":"Vorratsspeicher","goal":"Regelmäßig sparen wird zur Gewohnheit","minutes":"6 bis 9 Min.","scene":[{"speaker":"emma","text":"Ihr habt so viel gelernt! Jetzt kommt die Schatztruhen-Challenge.","name":"Emma"},{"speaker":"tala","text":"Eine Challenge? Was muss ich tun?"},{"speaker":"emma","text":"Vier Wochen lang legst du jede Woche etwas in deine Schatztruhe. Egal wie wenig.","name":"Emma"}],"lesson":[{"speaker":"emma","text":"Woche eins: Tala legt den ersten Taler in ihre Schatztruhe.","name":"Emma","image":"story.spar-insel.7.1"},{"speaker":"tala","text":"Jede Woche kommt etwas dazu. Die Säckchen werden immer voller!","image":"story.spar-insel.7.2"},{"speaker":"talo","text":"Wer etwas regelmäßig macht, gewöhnt sich daran. Irgendwann ist Sparen ganz normal, wie Zähneputzen."},{"speaker":"emma","text":"Ihr habt den Vorratsspeicher verdient. Schaut mal, was darin leuchtet!","name":"Emma","image":"story.spar-insel.7.3"},{"speaker":"gustav","text":"Emma, darf ich auch eine Spardose haben? Ich fange heute an!","name":"Gustav","image":"story.spar-insel.7.4"}],"game":{"type":"choice","title":"Dranbleiben","description":"Hilf Tala, bei der Challenge dranzubleiben.","task":"Was ist die beste Idee? Tippe auf deine Wahl.","rounds":[{"scene":[{"speaker":"tala","text":"Wann lege ich das Geld am besten in die Schatztruhe?"}],"question":"Was hilft am meisten?","options":[{"text":"Immer am selben Tag, gleich wenn das Taschengeld kommt","good":true,"reply":"Genau! Dann ist das Sparen schon erledigt, bevor das Geld ausgegeben ist."},{"text":"Am Ende der Woche, wenn etwas übrig ist","good":false,"reply":"Oft ist dann nichts mehr übrig. Besser gleich am Anfang sparen."}]},{"scene":[{"speaker":"tala","text":"Diese Woche habe ich nur 1 Taler übrig statt 3."}],"question":"Was soll Tala tun?","options":[{"text":"Den einen Taler trotzdem in die Schatztruhe legen","good":true,"reply":"Super! Auch wenig zählt. Wichtig ist, dass die Challenge weitergeht."},{"text":"Die Challenge abbrechen","good":false,"reply":"Ein Taler ist besser als keiner. Aufgeben muss Tala nicht."},{"text":"Diese Woche ausfallen lassen und nächste Woche 5 Taler sparen","good":false,"reply":"Das klappt selten. Besser jede Woche ein bisschen."}]},{"scene":[{"speaker":"gustav","text":"Wie merke ich, dass die Challenge klappt?","name":"Gustav"}],"question":"Was hilft Gustav?","options":[{"text":"Jede Woche ein Kästchen abhaken und den Stand ansehen","good":true,"reply":"So sieht Gustav, wie es vorangeht. Das macht Mut."},{"text":"Gar nicht darüber nachdenken","good":false,"reply":"Dann vergisst man es schnell. Abhaken hilft beim Dranbleiben."}]}],"done":{"speaker":"emma","text":"Jede Woche ein bisschen: So wird Sparen zur Gewohnheit.","name":"Emma"}},"estimate":{"speaker":"emma","question":"Was glaubst du: Wie viele Taler hat Tala nach 4 Wochen, wenn sie jede Woche 3 Taler in die Schatztruhe legt?","kind":"wheel","min":0,"max":30,"start":3,"unit":"Taler","unit_one":"Taler","answer":12,"reveal":{"speaker":"emma","text":"12 Taler! 4 Wochen mal 3 Taler. Und wer dranbleibt, macht das Sparen zur Gewohnheit."}},"taps":[{"after":1,"kind":"tap","text":"Läute die Start-Glocke für die Challenge.","symbol":"glocke","done":"Die Challenge beginnt!"},{"after":2,"kind":"drag","text":"Leg einen Taler in die Schatztruhe.","symbol":"muenze","done":"Klonk! Die erste Woche ist geschafft."}],"summary":{"speaker":"tala","text":"Ich mache die Challenge! Machst du mit? Leg in der Schatztruhe jede Woche etwas dazu."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station7/q1')::uuid, md5('taleria:stage1/spar-insel/station7')::uuid, 'Wie lange dauert die Schatztruhen-Challenge?', '["Vier Wochen, jede Woche ein bisschen","Einen einzigen Tag","Ein ganzes Jahr ohne Pause"]'::jsonb, 0, 'Vier Wochen reichen, damit Sparen zur Gewohnheit wird.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station7/q2')::uuid, md5('taleria:stage1/spar-insel/station7')::uuid, 'Wann spart man am besten?', '["Gleich, wenn das Taschengeld kommt","Am Ende des Monats, wenn etwas übrig ist","Nur an Geburtstagen"]'::jsonb, 0, 'Wer zuerst spart, hat das Geld schon sicher, bevor es weg ist.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station7/q3')::uuid, md5('taleria:stage1/spar-insel/station7')::uuid, 'Tala legt 4 Wochen lang jede Woche 3 Taler in die Schatztruhe. Wie viele Taler sind es dann?', '["12 Taler","7 Taler","3 Taler"]'::jsonb, 0, '4 mal 3 sind 12.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station7/q4')::uuid, md5('taleria:stage1/spar-insel/station7')::uuid, 'Was ist eine Gewohnheit?', '["Etwas, das man so oft macht, dass es ganz normal wird","Etwas, das man nur einmal macht","Etwas, das man nicht darf"]'::jsonb, 0, 'Wie Zähneputzen: Irgendwann denkt man gar nicht mehr darüber nach.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station7/q5')::uuid, md5('taleria:stage1/spar-insel/station7')::uuid, 'Diese Woche bleibt nur wenig Geld übrig. Was ist klug?', '["Trotzdem ein bisschen sparen","Die Challenge abbrechen","Gar nichts sparen und alles ausgeben"]'::jsonb, 0, 'Auch wenig zählt. Hauptsache, man bleibt dran.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station7/q6')::uuid, md5('taleria:stage1/spar-insel/station7')::uuid, 'Wer verhält sich auf der Spar-Insel wie ein guter Sparer?', '["Emma, die im Herbst Vorräte anlegt","Gustav, der alles sofort verbraucht","Niemand, auf der Insel spart keiner"]'::jsonb, 0, 'Emma legt zurück, wenn genug da ist. Das ist Sparen.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station7/q7')::uuid, md5('taleria:stage1/spar-insel/station7')::uuid, 'Gustav hat nie gespart. Jetzt ist seine Geige kaputt. Was ist das Problem?', '["Er hat kein Geld für die Reparatur.","Er braucht keine Geige mehr.","Emma muss die Reparatur bezahlen."]'::jsonb, 0, 'Ohne Rücklage fehlt das Geld, wenn etwas Unerwartetes passiert.', null, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/station8')::uuid, md5('taleria:stage1/spar-insel')::uuid, 80, 'exam', true, 150, '{"title":"Abschlussprüfung","number":8,"place":"Vorratsspeicher","goal":"Alles von der Spar-Insel wiederholen, dazu zwei Fragen von früheren Inseln","minutes":"8 bis 10 Min.","scene":[{"speaker":"emma","text":"Letzte Prüfung auf der Spar-Insel. Ab 8 richtigen Antworten öffne ich euch den Speicher ganz.","name":"Emma"},{"speaker":"tala","text":"Ich habe fleißig gespart: Wissen! Los geht''s."}],"summary":{"speaker":"emma","text":"Bestanden! Das Kartenstück aus dem Vorratsspeicher gehört euch. Gute Fahrt, ihr Vorratsmeister!","name":"Emma"},"exam":{"show":8,"review":2,"pass":8}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content, status = excluded.status;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q1')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Warum spart man?', '["Um sich später etwas Größeres zu leisten oder für Notfälle","Damit man nie wieder etwas kaufen muss","Weil Ausgeben schlecht ist"]'::jsonb, 0, 'Sparen schafft Möglichkeiten für später.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q2')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Warum hatte Gustav im Winter Probleme?', '["Er hatte im Herbst alles sofort verbraucht.","Er hatte zu viele Vorräte.","Emma hatte ihm nichts abgegeben."]'::jsonb, 0, 'Ohne Vorrat steht man in schlechten Zeiten ohne etwas da.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q3')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was ist ein Notgroschen?', '["Geld für unerwartete Ausgaben","Geld für den nächsten Kinobesuch","Eine Münze, die nichts mehr wert ist"]'::jsonb, 0, 'Ein Notgroschen hilft, wenn etwas Unerwartetes passiert.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q4')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Sparen bedeutet …', '["heute etwas zurücklegen, um es später zu nutzen.","nie wieder etwas kaufen.","Geld verschenken."]'::jsonb, 0, 'Gespartes Geld ist nicht weg, es wartet auf später.', 1, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q5')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was gehört zu einem guten Sparziel?', '["Was ich will, was es kostet und bis wann","Nur ein schönes Bild","Was die anderen sich wünschen"]'::jsonb, 0, 'Je klarer das Ziel, desto leichter das Sparen.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q6')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Dein Ziel kostet 40 Taler, du hast 10. Wie viel fehlt?', '["30 Taler","50 Taler","4 Taler"]'::jsonb, 0, '40 minus 10 sind 30.', 2, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q7')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Du sparst jede Woche 2 Taler. Wie viel hast du nach 10 Wochen?', '["20 Taler","12 Taler","2 Taler"]'::jsonb, 0, '10 mal 2 sind 20.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q8')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Wie viel sind 50 Cent am Tag nach einer Woche?', '["3,50 Euro","50 Cent","5 Euro"]'::jsonb, 0, '7 mal 50 Cent sind 3,50 Euro.', 3, 'draft', '{"question":"Wie viel sind 2 Euro am Tag nach einer Woche?","answers":["14 Euro","2 Euro","9 Euro"],"correct_index":0,"explanation":"7 mal 2 Euro sind 14 Euro."}'::jsonb)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q9')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was bedeutet „Kleinvieh macht auch Mist“?', '["Auch kleine Beträge werden mit der Zeit viel.","Nur große Beträge zählen.","Kleine Beträge gibt man am besten gleich aus."]'::jsonb, 0, 'Regelmäßige kleine Beträge summieren sich.', 3, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q10')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Eine Nuss jetzt oder drei morgen. Was zeigt diese Wahl?', '["Wer warten kann, bekommt oft mehr.","Wer zuerst nimmt, bekommt am meisten.","Warten lohnt sich nie."]'::jsonb, 0, 'Geduld zahlt sich häufig aus.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q11')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was hilft dir, geduldig zu bleiben?', '["Den Fortschritt sehen, zum Beispiel in der Schatztruhe","Jeden Tag in den Laden gehen","Das Ziel vergessen"]'::jsonb, 0, 'Wer sieht, dass es vorangeht, bleibt dran.', 4, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q12')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Du willst 30 Taler sparen und legst 5 pro Woche zurück. Wie lange dauert es?', '["6 Wochen","3 Wochen","25 Wochen"]'::jsonb, 0, '30 geteilt durch 5 sind 6.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q13')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was ist ein Sparplan?', '["Ein Plan, wie viel man wann zurücklegt","Eine Liste, was man alles kaufen will","Ein Stadtplan zur Bank"]'::jsonb, 0, 'Mit einem Sparplan weiß man, wann man das Ziel erreicht.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q14')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Du bekommst Geld geschenkt. Was ist klug für dein Sparziel?', '["Einen Teil in die Schatztruhe legen","Alles sofort ausgeben","Es verstecken und vergessen"]'::jsonb, 0, 'So kommt man dem Ziel schneller näher.', 5, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q15')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was ist ein Vorteil eines Kontos gegenüber dem Sparschwein?', '["Das Geld ist sicherer aufbewahrt.","Man kann das Geld jederzeit anfassen.","Man hört, wie es klimpert."]'::jsonb, 0, 'Auf dem Konto kann Geld nicht verloren gehen wie Bargeld.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q16')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was ist ein Vorteil eines Sparschweins?', '["Man sieht und hört, wie das Geld wächst.","Es ist gegen Diebstahl geschützt.","Das Geld kann nicht verloren gehen."]'::jsonb, 0, 'Gerade für den Anfang ist das Sehen und Anfassen gut.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q17')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Warum ist es keine gute Idee, Geld überall zu verteilen?', '["Man verliert den Überblick, und es geht leichter verloren.","Weil das Geld dann mehr wird","Weil Münzen dann rosten"]'::jsonb, 0, 'Ein fester Platz schafft Überblick.', 6, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q18')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was macht man bei der Schatztruhen-Challenge?', '["Mehrere Wochen regelmäßig etwas sparen","Eine Truhe kaufen","Alles auf einmal ausgeben"]'::jsonb, 0, 'Regelmäßigkeit macht Sparen zur Gewohnheit.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q19')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Emma legt im Herbst Vorräte an. Wie heißt das beim Geld?', '["Sparen","Leihen","Tauschen"]'::jsonb, 0, 'Vorräte anlegen ist wie Sparen.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status, beginner)
values (md5('taleria:stage1/spar-insel/station8/q20')::uuid, md5('taleria:stage1/spar-insel/station8')::uuid, 'Was passiert, wenn man nie spart?', '["Für größere Wünsche oder Notfälle fehlt das Geld.","Man hat später automatisch mehr.","Nichts, das ist egal."]'::jsonb, 0, 'Ohne Rücklage ist man auf Glück angewiesen.', 7, 'draft', null)
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station, status = excluded.status,
  beginner = excluded.beginner;

-- Ankerplatz 1: Das Tagebuch des Matrosen
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/dive1')::uuid, md5('taleria:stage1/spar-insel')::uuid, 25, 'review_stop', true, 50, '{"title":"Das Tagebuch des Matrosen","kind":"dive","number":1,"dive":{"game":"pearls","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Ein altes Tagebuch! Ein Matrose schreibt: Ich wollte immer ein eigenes Boot. Aber nie hatte ich genug Geld."},{"speaker":"talo","text":"Hier steht noch mehr: Ich habe nie aufgeschrieben, was das Boot kostet, und immer gespart, wenn gerade etwas übrig war."}],"question":"Was hat der Matrose falsch gemacht?","answers":["Er hatte kein klares Ziel mit Preis und hat nicht regelmäßig gespart.","Er hat zu viel gespart.","Er hätte sich das Boot gar nicht wünschen dürfen."],"correct_index":0,"explanation":"Mit einem klaren Ziel und einem Sparplan hätte er gewusst, wie viel und wie lange er sparen muss."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/spar-insel/dive1/find')::uuid, 'spar-insel-fund-1', 'wreck_item', 'Tagebuch eines Matrosen', 'collectible.spar-insel.1', md5('taleria:stage1/spar-insel/dive1')::uuid, 41, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 2: Die alte Spardose
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/dive2')::uuid, md5('taleria:stage1/spar-insel')::uuid, 45, 'review_stop', true, 50, '{"title":"Die alte Spardose","kind":"dive","number":2,"dive":{"game":"shell_count","questions":4,"wreck":{"scene":[{"speaker":"talo","text":"Eine alte Spardose! Daneben ein Zettel: Jede Woche 2 Taler, 12 Wochen lang."},{"speaker":"tala","text":"Wie viel da wohl drin ist?"}],"question":"Wie viele Taler sind nach 12 Wochen in der Spardose?","answers":["24 Taler","14 Taler","12 Taler"],"correct_index":0,"explanation":"12 Wochen mal 2 Taler sind 24 Taler. Regelmäßig ein bisschen wird viel."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/spar-insel/dive2/find')::uuid, 'spar-insel-fund-2', 'wreck_item', 'Alte Spardose', 'collectible.spar-insel.2', md5('taleria:stage1/spar-insel/dive2')::uuid, 42, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

-- Ankerplatz 3: Die Schatzkammer der alten Crew
insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/spar-insel/dive3')::uuid, md5('taleria:stage1/spar-insel')::uuid, 65, 'review_stop', true, 50, '{"title":"Die Schatzkammer der alten Crew","kind":"dive","number":3,"dive":{"game":"treasure_chest","questions":4,"wreck":{"scene":[{"speaker":"tala","text":"Ein Schlüssel! Die alte Crew hatte ihr Geld an drei Orten: in einem Strumpf, in einer offenen Kiste an Deck und verschlossen in der Schatzkammer."},{"speaker":"talo","text":"Nach einem Sturm war nur noch ein Teil da."}],"question":"Wo war das Geld der alten Crew am sichersten?","answers":["Verschlossen in der Schatzkammer","In der offenen Kiste an Deck","Im Strumpf unter der Hängematte"],"correct_index":0,"explanation":"Ein sicherer, fester Ort schützt Gespartes. Heute ist das für größere Beträge oft ein Konto."}}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, xp_reward = excluded.xp_reward, content = excluded.content,
  status = excluded.status;
insert into public.collectibles (id, slug, kind, title, asset_key, station_id, sort_order, status)
values (md5('taleria:stage1/spar-insel/dive3/find')::uuid, 'spar-insel-fund-3', 'wreck_item', 'Schlüssel der Schatzkammer', 'collectible.spar-insel.3', md5('taleria:stage1/spar-insel/dive3')::uuid, 43, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, station_id = excluded.station_id,
  sort_order = excluded.sort_order,
  status = excluded.status;

delete from public.quiz_questions q using public.stations s
where q.station_id = s.id and s.island_id = md5('taleria:stage1/spar-insel')::uuid
  and q.id not in (md5('taleria:stage1/spar-insel/sea1/q1')::uuid, md5('taleria:stage1/spar-insel/sea1/q2')::uuid, md5('taleria:stage1/spar-insel/sea1/q3')::uuid, md5('taleria:stage1/spar-insel/sea1/q4')::uuid, md5('taleria:stage1/spar-insel/sea1/q5')::uuid, md5('taleria:stage1/spar-insel/sea1/q6')::uuid, md5('taleria:stage1/spar-insel/sea2/q1')::uuid, md5('taleria:stage1/spar-insel/sea2/q2')::uuid, md5('taleria:stage1/spar-insel/sea2/q3')::uuid, md5('taleria:stage1/spar-insel/sea2/q4')::uuid, md5('taleria:stage1/spar-insel/sea2/q5')::uuid, md5('taleria:stage1/spar-insel/sea2/q6')::uuid, md5('taleria:stage1/spar-insel/station1/q1')::uuid, md5('taleria:stage1/spar-insel/station1/q2')::uuid, md5('taleria:stage1/spar-insel/station1/q3')::uuid, md5('taleria:stage1/spar-insel/station1/q4')::uuid, md5('taleria:stage1/spar-insel/station1/q5')::uuid, md5('taleria:stage1/spar-insel/station1/q6')::uuid, md5('taleria:stage1/spar-insel/station1/q7')::uuid, md5('taleria:stage1/spar-insel/station2/q1')::uuid, md5('taleria:stage1/spar-insel/station2/q2')::uuid, md5('taleria:stage1/spar-insel/station2/q3')::uuid, md5('taleria:stage1/spar-insel/station2/q4')::uuid, md5('taleria:stage1/spar-insel/station2/q5')::uuid, md5('taleria:stage1/spar-insel/station2/q6')::uuid, md5('taleria:stage1/spar-insel/station2/q7')::uuid, md5('taleria:stage1/spar-insel/station3/q1')::uuid, md5('taleria:stage1/spar-insel/station3/q2')::uuid, md5('taleria:stage1/spar-insel/station3/q3')::uuid, md5('taleria:stage1/spar-insel/station3/q4')::uuid, md5('taleria:stage1/spar-insel/station3/q5')::uuid, md5('taleria:stage1/spar-insel/station3/q6')::uuid, md5('taleria:stage1/spar-insel/station3/q7')::uuid, md5('taleria:stage1/spar-insel/station4/q1')::uuid, md5('taleria:stage1/spar-insel/station4/q2')::uuid, md5('taleria:stage1/spar-insel/station4/q3')::uuid, md5('taleria:stage1/spar-insel/station4/q4')::uuid, md5('taleria:stage1/spar-insel/station4/q5')::uuid, md5('taleria:stage1/spar-insel/station4/q6')::uuid, md5('taleria:stage1/spar-insel/station4/q7')::uuid, md5('taleria:stage1/spar-insel/station5/q1')::uuid, md5('taleria:stage1/spar-insel/station5/q2')::uuid, md5('taleria:stage1/spar-insel/station5/q3')::uuid, md5('taleria:stage1/spar-insel/station5/q4')::uuid, md5('taleria:stage1/spar-insel/station5/q5')::uuid, md5('taleria:stage1/spar-insel/station5/q6')::uuid, md5('taleria:stage1/spar-insel/station5/q7')::uuid, md5('taleria:stage1/spar-insel/station6/q1')::uuid, md5('taleria:stage1/spar-insel/station6/q2')::uuid, md5('taleria:stage1/spar-insel/station6/q3')::uuid, md5('taleria:stage1/spar-insel/station6/q4')::uuid, md5('taleria:stage1/spar-insel/station6/q5')::uuid, md5('taleria:stage1/spar-insel/station6/q6')::uuid, md5('taleria:stage1/spar-insel/station6/q7')::uuid, md5('taleria:stage1/spar-insel/station7/q1')::uuid, md5('taleria:stage1/spar-insel/station7/q2')::uuid, md5('taleria:stage1/spar-insel/station7/q3')::uuid, md5('taleria:stage1/spar-insel/station7/q4')::uuid, md5('taleria:stage1/spar-insel/station7/q5')::uuid, md5('taleria:stage1/spar-insel/station7/q6')::uuid, md5('taleria:stage1/spar-insel/station7/q7')::uuid, md5('taleria:stage1/spar-insel/station8/q1')::uuid, md5('taleria:stage1/spar-insel/station8/q2')::uuid, md5('taleria:stage1/spar-insel/station8/q3')::uuid, md5('taleria:stage1/spar-insel/station8/q4')::uuid, md5('taleria:stage1/spar-insel/station8/q5')::uuid, md5('taleria:stage1/spar-insel/station8/q6')::uuid, md5('taleria:stage1/spar-insel/station8/q7')::uuid, md5('taleria:stage1/spar-insel/station8/q8')::uuid, md5('taleria:stage1/spar-insel/station8/q9')::uuid, md5('taleria:stage1/spar-insel/station8/q10')::uuid, md5('taleria:stage1/spar-insel/station8/q11')::uuid, md5('taleria:stage1/spar-insel/station8/q12')::uuid, md5('taleria:stage1/spar-insel/station8/q13')::uuid, md5('taleria:stage1/spar-insel/station8/q14')::uuid, md5('taleria:stage1/spar-insel/station8/q15')::uuid, md5('taleria:stage1/spar-insel/station8/q16')::uuid, md5('taleria:stage1/spar-insel/station8/q17')::uuid, md5('taleria:stage1/spar-insel/station8/q18')::uuid, md5('taleria:stage1/spar-insel/station8/q19')::uuid, md5('taleria:stage1/spar-insel/station8/q20')::uuid);

insert into public.badges (id, slug, kind, island_id, title, asset_key, sort_order, status)
values (md5('taleria:stage1/spar-insel/badge')::uuid, 'spar-insel', 'island', md5('taleria:stage1/spar-insel')::uuid, 'Vorratsmeister', 'badge.spar-insel', 4, 'draft')
on conflict (id) do update set
  title = excluded.title, asset_key = excluded.asset_key, sort_order = excluded.sort_order,
  status = excluded.status;

insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/spar-insel/prompt1')::uuid, md5('taleria:stage1/spar-insel')::uuid, 'Wofür hast du als Kind gespart?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/spar-insel/prompt2')::uuid, md5('taleria:stage1/spar-insel')::uuid, 'Wofür sparen wir als Familie gerade?', 'draft')
on conflict (id) do update set text = excluded.text, status = excluded.status;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/spar-insel')::uuid and status <> 'draft';

-- 5. Taschengeld-Bucht (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/taschengeld-bucht')::uuid, 'taschengeld-bucht', 1, 2, 5, 0.28, 0.7, 'main', 'Taschengeld-Bucht', '{"goal":"Taschengeld einteilen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/taschengeld-bucht')::uuid and status <> 'draft';

-- 6. Marktinsel (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/marktinsel')::uuid, 'marktinsel', 1, 2, 6, 0.72, 0.635, 'main', 'Marktinsel', '{"goal":"Einkaufen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/marktinsel')::uuid and status <> 'draft';

-- 7. Werbe-Riff (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/werbe-riff')::uuid, 'werbe-riff', 1, 2, 7, 0.5, 0.57, 'main', 'Werbe-Riff', '{"goal":"Werbung durchschauen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/werbe-riff')::uuid and status <> 'draft';

-- 8. Verdienst-Insel (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/verdienst-insel')::uuid, 'verdienst-insel', 1, 2, 8, 0.28, 0.505, 'main', 'Verdienst-Insel', '{"goal":"Geld verdienen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/verdienst-insel')::uuid and status <> 'draft';

-- 9. Bank-Insel (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/bank-insel')::uuid, 'bank-insel', 1, 3, 9, 0.72, 0.44, 'main', 'Bank-Insel', '{"goal":"Bank und Konto","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/bank-insel')::uuid and status <> 'draft';

-- 10. Zins-Insel (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/zins-insel')::uuid, 'zins-insel', 1, 3, 10, 0.5, 0.375, 'main', 'Zins-Insel', '{"goal":"Zinsen und Inflation","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/zins-insel')::uuid and status <> 'draft';

-- 11. Leih-Lagune (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/leih-lagune')::uuid, 'leih-lagune', 1, 3, 11, 0.28, 0.31, 'main', 'Leih-Lagune', '{"goal":"Leihen und Schulden","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/leih-lagune')::uuid and status <> 'draft';

-- 12. Sicherheits-Festung (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/sicherheits-festung')::uuid, 'sicherheits-festung', 1, 3, 12, 0.72, 0.245, 'main', 'Sicherheits-Festung', '{"goal":"Sicher mit Geld","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/sicherheits-festung')::uuid and status <> 'draft';

-- 13. Risiko-Klippen (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/risiko-klippen')::uuid, 'risiko-klippen', 1, 4, 13, 0.5, 0.18, 'main', 'Risiko-Klippen', '{"goal":"Risiko und Vorsorge","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/risiko-klippen')::uuid and status <> 'draft';

-- 14. Zukunftsinsel (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/zukunftsinsel')::uuid, 'zukunftsinsel', 1, 4, 14, 0.28, 0.115, 'main', 'Zukunftsinsel', '{"goal":"Planen und Investieren als Idee","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/zukunftsinsel')::uuid and status <> 'draft';

-- 15. Schatzinsel (Nebel), Status: entwurf
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, content)
values (md5('taleria:stage1/schatzinsel')::uuid, 'schatzinsel', 1, 4, 15, 0.72, 0.05, 'main', 'Schatzinsel', '{"goal":"Abschluss und Goldene Schatzkarte","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- Status der Insel erst jetzt, wenn alles auf der Insel da ist.
update public.islands set status = 'draft' where id = md5('taleria:stage1/schatzinsel')::uuid and status <> 'draft';

-- Orden für Inseln, die schon vor ihrem Orden abgeschlossen waren.
insert into public.child_badges (child_id, badge_id)
select c.child_id, b.id from public.island_completions c join public.badges b on b.island_id = c.island_id
on conflict on constraint child_badges_once do nothing;

-- Begegnung: Meister Taleron, Status: entwurf
insert into public.encounters (id, slug, type, title, asset_key, question_count, xp_reward, after_island_id, content, status)
values (md5('taleria:encounter/taleron-raetsel')::uuid, 'taleron-raetsel', 'taleron', 'Meister Taleron', 'encounter.taleron', 3, 20, null, '{"first_scene":[{"speaker":"tala","text":"Talo, schau mal! Unter dem Schiff bewegt sich etwas. Etwas sehr Großes."},{"speaker":"taleron","text":"Hoho! Wer segelt denn da durch mein Meer? Eine neue Crew, wie schön.","name":"Stimme aus dem Meer"},{"speaker":"talo","text":"Keine Angst! Das ist Meister Taleron, der Hüter des Meeres. Er ist uralt und sehr freundlich."},{"speaker":"taleron","text":"Ich lasse jedes Schiff passieren, das drei Rätsel löst. Rätsel über Dinge, die ihr schon gelernt habt."},{"speaker":"tala","text":"Und wenn wir uns irren?"},{"speaker":"taleron","text":"Dann erkläre ich es euch, und ihr versucht es gleich noch einmal. Bei mir geht niemand unter."}],"scene":[{"speaker":"taleron","text":"Da seid ihr ja wieder! Mal sehen, was ihr noch wisst. Drei Rätsel, dann ist der Weg frei."}],"right":{"speaker":"taleron","text":"Hoho, richtig! Das hast du gut behalten."},"wrong":{"speaker":"taleron","text":"Nicht ganz. Hör gut zu, dann klappt es beim nächsten Versuch."},"success":{"speaker":"taleron","text":"Drei Rätsel, drei Lösungen. Der Weg ist frei, junge Crew. Gute Fahrt!"}}'::jsonb, 'draft')
on conflict (id) do update set
  type = excluded.type, title = excluded.title, asset_key = excluded.asset_key,
  question_count = excluded.question_count, xp_reward = excluded.xp_reward,
  after_island_id = excluded.after_island_id, content = excluded.content, status = excluded.status;

commit;
