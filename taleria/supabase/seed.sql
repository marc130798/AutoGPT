-- Seed-Daten für die TESTUMGEBUNG. Nie in die Live-Datenbank einspielen.
-- Automatisch erzeugt aus content/stufe1/*.json mit: dart run tool/build_seed.dart
-- Nicht von Hand ändern, sondern die Inhaltsdateien bearbeiten und neu erzeugen.

begin;

-- Inhalts-Vorschau: Kinder sehen in der Testumgebung auch Entwürfe.
insert into public.app_settings (key, value) values ('content_preview', 'true'::jsonb)
on conflict (key) do update set value = excluded.value;

-- 1. Hafen von Taleria
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/hafen')::uuid, 'hafen', 1, 1, 1, 0.5, 0.96, 'main', 'Hafen von Taleria', 'draft', '{"goal":"Das Kind kennt Talo und Tala, weiß, was Geld ist, wie es entstanden ist, woher es kommt, warum Dinge etwas kosten und hat ein erstes Gefühl für Preise.","access":"free","badge":"Erster Landgang","real_life_task":{"title":"Preis-Detektiv","text":"Suche beim nächsten Einkauf drei Produkte, schätze vorher ihren Preis und vergleiche dann mit dem echten Preis. Überlege mit deinen Eltern, wer an einem davon alles mitverdient."}}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station1')::uuid, md5('taleria:stage1/hafen')::uuid, 1, 'practice', true, 50, '{"title":"Willkommen an Bord","place":"Schiffssteg","goal":"Ankommen, Figuren und App kennen","minutes":"5 bis 8 Min.","kind":"onboarding"}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station2')::uuid, md5('taleria:stage1/hafen')::uuid, 2, 'quiz', true, 100, '{"title":"Was ist Geld?","place":"Hafenkontor","goal":"Geld als Tauschmittel verstehen","minutes":"7 bis 10 Min.","video_key":"video.station.hafen.2","scene":[{"speaker":"tala","text":"Ein Fischbrötchen, bitte! Ich bezahle mit meinem goldenen Halstuch."},{"speaker":"haendler","text":"Ein Halstuch? Tut mir leid, ich brauche Mehl für meine Brötchen.","name":"Händler"},{"speaker":"tala","text":"Mehl hab ich nicht. Und jetzt?"},{"speaker":"talo","text":"Genau für solche Fälle haben die Menschen das Geld erfunden."}],"lesson":[{"speaker":"talo","text":"Beim Tauschen muss jeder genau das haben, was der andere gerade braucht. Das klappt nur selten."},{"speaker":"talo","text":"Geld nimmt fast jeder an. Der Händler kann damit später sein Mehl kaufen."},{"speaker":"tala","text":"Und Geld kann man aufheben! Ein Fischbrötchen wird schlecht, ein Taler nicht."},{"speaker":"talo","text":"Mit Geld bekommt außerdem alles einen Preis in derselben Einheit. So kann man Preise vergleichen."}],"game":{"type":"barter","title":"Tausch-Spiel","description":"Tala versucht ohne Geld an ein Fischbrötchen zu kommen und merkt, wie umständlich Tauschen ist."},"summary":{"speaker":"talo","text":"Geld ist ein Tauschmittel: Fast jeder nimmt es an, man kann es aufheben und damit Preise vergleichen."},"quiz":{"show":5}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q1')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Warum wollte der Händler Talas Halstuch nicht?', '["Er brauchte Mehl, kein Halstuch.","Das Halstuch war ihm zu klein.","Er mag die Farbe Gold nicht."]'::jsonb, 0, 'Beim Tauschen muss jeder genau das haben, was der andere gerade braucht. Das klappt nur selten.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q2')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Was ist der größte Vorteil von Geld gegenüber Tauschen?', '["Fast jeder nimmt es an.","Es ist schwerer als ein Halstuch.","Man kann es essen."]'::jsonb, 0, 'Weil fast jeder Geld annimmt, kann der Händler damit später sein Mehl kaufen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q3')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Tala bekommt heute 5 Taler und will erst nächste Woche etwas kaufen. Geht das?', '["Ja, Geld kann man aufheben.","Nein, Geld verschwindet am Abend.","Nur wenn Talo es erlaubt."]'::jsonb, 0, 'Ein Fischbrötchen wird schlecht, Geld kann man aufheben und später ausgeben.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q4')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Ein Apfel kostet 50 Cent, eine Birne 80 Cent. Warum kannst du das so leicht vergleichen?', '["Beide Preise sind in derselben Währung angegeben.","Weil Birnen größer sind.","Weil Äpfel rot sind."]'::jsonb, 0, 'Mit Geld bekommt alles einen Preis in derselben Einheit, so sieht man sofort, was teurer ist.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q5')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Womit haben Menschen früher manchmal bezahlt, bevor es Münzen gab?', '["Mit Muscheln oder Salz","Mit Kreditkarten","Mit Smartphones"]'::jsonb, 0, 'Früher wurden seltene Dinge wie bestimmte Muscheln oder Salz als Zahlungsmittel genutzt.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q6')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Wie heißt unsere Währung in Deutschland?', '["Euro","Dollar","Taler"]'::jsonb, 0, 'Der Taler ist das Geld in Taleria, bei uns bezahlt man mit Euro.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q7')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Warum ist ein 10-Euro-Schein etwas wert, obwohl er nur aus Papier ist?', '["Weil alle darauf vertrauen und ihn annehmen.","Weil er aus Gold gemacht ist.","Weil er so schön bunt ist."]'::jsonb, 0, 'Geld funktioniert, weil sich alle darauf verlassen, dass andere es auch annehmen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q8')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Was ist beim Tauschen ohne Geld besonders schwierig?', '["Jemanden zu finden, der genau das hat, was ich will, und genau das will, was ich habe.","Etwas in die Hand zu nehmen.","Freundlich zu sein."]'::jsonb, 0, 'Beide Seiten müssen gleichzeitig zufrieden sein. Mit Geld ist das viel einfacher.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q9')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Der Händler bekommt für ein Fischbrötchen 3 Taler. Was kann er damit tun?', '["Damit später bei jemand anderem Mehl kaufen","Nur Fischbrötchen kaufen","Gar nichts, Taler sind wertlos"]'::jsonb, 0, 'Mit Geld kann der Händler bei jedem einkaufen, der Geld annimmt.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station2/q10')::uuid, md5('taleria:stage1/hafen/station2')::uuid, 'Was macht Geld zu einem guten Tauschmittel?', '["Fast jeder nimmt es an und man kann es aufheben.","Es ist besonders bunt.","Man kann damit Fische fangen."]'::jsonb, 0, 'Ein gutes Tauschmittel wird von vielen angenommen und behält seinen Wert eine Weile.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station3')::uuid, md5('taleria:stage1/hafen')::uuid, 3, 'game', true, 100, '{"title":"Geld früher und heute","place":"Altes Lagerhaus","goal":"Geld hat sich entwickelt, die Idee ist gleich geblieben","minutes":"6 bis 9 Min.","video_key":"video.station.hafen.3","scene":[{"speaker":"tala","text":"Talo, hier im Lagerhaus stehen lauter alte Kisten!"},{"speaker":"talo","text":"Lass uns reinschauen. Muscheln, Salz, Metallstücke, alte Münzen und Scheine …"},{"speaker":"tala","text":"Das war alles mal Geld? Sogar Salz?"}],"lesson":[{"speaker":"talo","text":"Früher haben Menschen mit seltenen Dingen bezahlt, zum Beispiel mit bestimmten Muscheln oder mit Salz."},{"speaker":"talo","text":"Später kamen Münzen aus Metall. Sie halten lange und lassen sich leicht abzählen."},{"speaker":"tala","text":"Dann kamen Scheine aus Papier. Viel leichter als ein Sack voller Münzen!"},{"speaker":"talo","text":"Heute bezahlen viele mit Karte oder Handy. Das Geld kommt dann von einem Konto. Die Idee ist gleich geblieben: Alle nehmen es an."}],"game":{"type":"timeline","title":"Zeitstrahl","description":"Ordne Muscheln, Münzen, Papiergeld sowie Karte und Handy auf einem Zeitstrahl von früher bis heute."},"summary":{"speaker":"tala","text":"Geld hat sich verändert, aber es funktioniert immer gleich: Alle vertrauen darauf und nehmen es an."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station3/q1')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Was haben Menschen früher manchmal als Geld benutzt?', '["Seltene Muscheln","Plastiktüten","Kieselsteine, die überall herumliegen"]'::jsonb, 0, 'Als Geld taugt nur, was selten ist. Kieselsteine liegen überall, bestimmte Muscheln nicht.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station3/q2')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Warum waren Münzen praktischer als Salz?', '["Sie halten lange und sind leicht zu zählen.","Sie schmecken besser.","Sie sind leichter als Luft."]'::jsonb, 0, 'Salz kann nass werden und zerfallen. Münzen bleiben gleich und man kann sie abzählen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station3/q3')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Was kam in der Geschichte des Geldes zuerst?', '["Muscheln und andere seltene Dinge","Bezahlen mit dem Handy","Geldscheine"]'::jsonb, 0, 'Erst wurden seltene Dinge genutzt, dann Münzen, dann Scheine und heute auch digitales Geld.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station3/q4')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Warum wurden Geldscheine erfunden?', '["Große Beträge in Münzen sind schwer und unpraktisch.","Weil Münzen verboten wurden","Damit man Papier sparen kann"]'::jsonb, 0, 'Ein Schein kann viele Münzen ersetzen und passt in jede Tasche.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station3/q5')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Woher kommt das Geld, wenn du mit Karte oder Handy bezahlst?', '["Von einem Konto","Aus dem Handy-Akku","Aus der Kasse im Laden"]'::jsonb, 0, 'Beim digitalen Bezahlen wird Geld von einem Konto auf ein anderes übertragen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station3/q6')::uuid, md5('taleria:stage1/hafen/station3')::uuid, 'Was ist bei allen Arten von Geld gleich geblieben?', '["Man kann damit bezahlen, weil alle es annehmen.","Es ist immer aus Gold.","Es ist immer rund."]'::jsonb, 0, 'Ob Muschel, Münze oder Karte: Geld funktioniert, weil alle es annehmen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station4')::uuid, md5('taleria:stage1/hafen')::uuid, 4, 'game', true, 100, '{"title":"Münzen und Scheine","place":"Münzschublade im Kontor","goal":"Euro-Münzen und Scheine kennen, Beträge zusammensetzen","minutes":"7 bis 10 Min.","scene":[{"speaker":"tala","text":"In der Münzschublade herrscht Chaos! Alles liegt durcheinander."},{"speaker":"talo","text":"Dann sortieren wir. Kennst du alle Euro-Münzen und Scheine?"}],"lesson":[{"speaker":"talo","text":"Es gibt 8 Euro-Münzen: 1, 2, 5, 10, 20 und 50 Cent sowie 1 und 2 Euro."},{"speaker":"tala","text":"Und 100 Cent sind genau 1 Euro!"},{"speaker":"talo","text":"Der kleinste Schein ist der 5-Euro-Schein. Für größere Beträge gibt es zum Beispiel Scheine für 10, 20 und 50 Euro."},{"speaker":"tala","text":"Mein Tipp: Wer einen Betrag mit möglichst wenigen Münzen legen will, nimmt zuerst die großen."},{"speaker":"talo","text":"Geld gibt es übrigens auch digital auf einem Konto. Man sieht es nicht, aber es ist genauso viel wert."}],"game":{"type":"coins","title":"Münzschublade","description":"Münzen und Scheine sortieren, Beträge mit möglichst wenigen Münzen legen und Wechselgeld herausgeben."},"summary":{"speaker":"talo","text":"Jetzt kennst du die Euro-Münzen und Scheine und kannst Beträge zusammensetzen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station4/q1')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Welche Münze gibt es beim Euro nicht?', '["3 Cent","2 Cent","50 Cent"]'::jsonb, 0, 'Es gibt 1, 2, 5, 10, 20 und 50 Cent sowie 1 und 2 Euro, aber keine 3-Cent-Münze.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station4/q2')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Wie viel sind zwei 50-Cent-Münzen zusammen?', '["1 Euro","50 Cent","100 Euro"]'::jsonb, 0, '50 Cent plus 50 Cent sind 100 Cent, also 1 Euro.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station4/q3')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Wie legst du 70 Cent mit möglichst wenigen Münzen?', '["50 Cent und 20 Cent","Sieben 10-Cent-Münzen","Vierzehn 5-Cent-Münzen"]'::jsonb, 0, 'Große Münzen zuerst: 50 plus 20 sind 70 Cent mit nur zwei Münzen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station4/q4')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Du zahlst mit einem 5-Euro-Schein für etwas, das 3,50 Euro kostet. Wie viel bekommst du zurück?', '["1,50 Euro","2,50 Euro","50 Cent"]'::jsonb, 0, '5 Euro minus 3,50 Euro sind 1,50 Euro.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station4/q5')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Was ist mehr wert: drei 20-Cent-Münzen oder eine 50-Cent-Münze?', '["Drei 20-Cent-Münzen","Die 50-Cent-Münze","Beides gleich viel"]'::jsonb, 0, 'Drei mal 20 Cent sind 60 Cent, das ist mehr als 50 Cent.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station4/q6')::uuid, md5('taleria:stage1/hafen/station4')::uuid, 'Gibt es Geld auch, ohne dass man es anfassen kann?', '["Ja, auf einem Konto","Nein, Geld ist immer aus Metall oder Papier","Nur in Videospielen"]'::jsonb, 0, 'Auf einem Konto ist Geld gespeichert, ohne dass Münzen oder Scheine herumliegen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station5')::uuid, md5('taleria:stage1/hafen')::uuid, 5, 'game', true, 100, '{"title":"Woher kommt Geld?","place":"Werft","goal":"Geld verdient man durch Arbeit","minutes":"6 bis 9 Min.","video_key":"video.station.hafen.5","scene":[{"speaker":"bootsbauer","text":"Puh, heute haben wir das Boot vom Fischer repariert. Morgen ist Zahltag!","name":"Bootsbauer"},{"speaker":"tala","text":"Zahltag? Bekommt ihr Geld fürs Hämmern?"},{"speaker":"talo","text":"Sie bekommen Lohn, weil sie etwas leisten, das andere brauchen."}],"lesson":[{"speaker":"talo","text":"Die meisten Erwachsenen verdienen ihr Geld mit Arbeit. Dafür bekommen sie Lohn oder Gehalt."},{"speaker":"tala","text":"Die Bootsbauer reparieren Schiffe, der Bäcker backt Brot, die Ärztin hilft Kranken."},{"speaker":"talo","text":"Hergestellt wird Euro-Geld nur von bestimmten Stellen. Wer selbst Geld druckt, macht Falschgeld, und das ist verboten."},{"speaker":"tala","text":"Also: Geld drucken darf man nicht, Geld verdienen schon!"}],"game":{"type":"matching","title":"Berufe zuordnen","description":"Ordne jedem Beruf zu, was er für andere leistet."},"summary":{"speaker":"talo","text":"Geld verdient man, indem man etwas leistet, das andere brauchen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station5/q1')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Wofür bekommt die Bäckerin Geld?', '["Für das Brot, das sie für andere backt","Fürs Ausschlafen","Weil sie eine Bäckermütze trägt"]'::jsonb, 0, 'Sie leistet etwas, das andere brauchen und wofür sie bezahlen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station5/q2')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Wie nennt man das Geld, das man für seine Arbeit bekommt?', '["Lohn oder Gehalt","Wechselgeld","Trinkgeld"]'::jsonb, 0, 'Für Arbeit gibt es Lohn oder Gehalt.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station5/q3')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Wer darf Euro-Geldscheine herstellen?', '["Nur bestimmte Stellen, die dafür zuständig sind","Jeder mit einem guten Drucker","Jeder Laden"]'::jsonb, 0, 'Nur bestimmte Stellen dürfen Euro-Geld herstellen. Selbstgemachtes Geld ist Falschgeld.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station5/q4')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Warum bekommen die Bootsbauer Geld vom Fischer?', '["Weil sie sein Boot repariert haben","Weil sie Freunde sind","Weil Möwen zugeschaut haben"]'::jsonb, 0, 'Der Fischer bezahlt für eine Leistung, die er braucht.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station5/q5')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Was ist es, wenn jemand selbst Geldscheine druckt?', '["Falschgeld, und das ist verboten","Ein toller Trick, um reich zu werden","Erlaubt, wenn die Scheine hübsch sind"]'::jsonb, 0, 'Falschgeld schadet allen, deshalb ist es streng verboten.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station5/q6')::uuid, md5('taleria:stage1/hafen/station5')::uuid, 'Welcher Satz stimmt?', '["Geld verdient man meistens durch Arbeit.","Geld wächst auf Bäumen.","Geld bekommt nur, wer laut fragt."]'::jsonb, 0, 'Für die meisten Menschen kommt das Geld aus ihrer Arbeit.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station6')::uuid, md5('taleria:stage1/hafen')::uuid, 6, 'game', true, 100, '{"title":"Warum kostet etwas etwas?","place":"Fischbrötchen-Stand","goal":"Ein Preis besteht aus Kosten und Gewinn","minutes":"7 bis 10 Min.","video_key":"video.station.hafen.6","scene":[{"speaker":"tala","text":"Was? So viel kostet ein Fischbrötchen? Der Fisch schwimmt doch einfach im Meer herum!"},{"speaker":"verkaeuferin","text":"Der Fisch muss gefangen werden, das Brötchen gebacken, und mein Stand kostet Miete.","name":"Verkäuferin"},{"speaker":"talo","text":"Lass uns den Preis mal auseinandernehmen."}],"lesson":[{"speaker":"talo","text":"Im Preis stecken die Zutaten: Fisch, Brötchen, Zwiebeln."},{"speaker":"talo","text":"Dazu kommen die Miete für den Stand und der Lohn für die Verkäuferin."},{"speaker":"tala","text":"Und was übrig bleibt, ist der Gewinn! Davon kann der Stand zum Beispiel einen neuen Grill kaufen."},{"speaker":"talo","text":"Ohne Gewinn lohnt sich der Stand nicht. Ist der Preis zu hoch, kaufen die Leute woanders."}],"game":{"type":"price_stack","title":"Preis-Säule","description":"Staple Zutaten, Miete, Lohn und Gewinn, bis die Säule genau den Preis ergibt."},"summary":{"speaker":"tala","text":"Ein Preis besteht aus allen Kosten und einem kleinen Gewinn."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station6/q1')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Was gehört NICHT zu den Kosten eines Fischbrötchen-Stands?', '["Das Taschengeld der Kunden","Die Miete für den Stand","Der Fisch"]'::jsonb, 0, 'Kosten hat der Stand selbst: Zutaten, Miete, Lohn. Das Taschengeld der Kunden gehört nicht dazu.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station6/q2')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Ein Brötchen kostet den Bäcker 30 Cent. Er verkauft es für 40 Cent. Wie hoch ist sein Gewinn?', '["10 Cent","40 Cent","70 Cent"]'::jsonb, 0, '40 Cent minus 30 Cent Kosten sind 10 Cent Gewinn.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station6/q3')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Warum zahlt der Fischbrötchen-Stand Miete?', '["Weil er einen Platz nutzt, der jemand anderem gehört","Weil die Möwen es verlangen","Weil Miete lecker ist"]'::jsonb, 0, 'Wer einen Platz oder Raum nutzt, der jemand anderem gehört, zahlt dafür Miete.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station6/q4')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Was passiert, wenn ein Stand dauerhaft mehr ausgibt, als er einnimmt?', '["Er macht Verlust und muss bald schließen.","Er wird immer reicher.","Gar nichts"]'::jsonb, 0, 'Wer mehr ausgibt als einnimmt, macht Verlust. Das geht nicht lange gut.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station6/q5')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Wofür kann ein Stand seinen Gewinn nutzen?', '["Zum Beispiel für einen neuen Grill","Für gar nichts","Er muss ihn ins Meer werfen."]'::jsonb, 0, 'Mit dem Gewinn kann man Neues anschaffen, sparen oder davon leben.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station6/q6')::uuid, md5('taleria:stage1/hafen/station6')::uuid, 'Was passiert wahrscheinlich, wenn ein Stand viel zu viel für ein Fischbrötchen verlangt?', '["Viele Kunden kaufen woanders.","Es kommen noch mehr Kunden.","Die Fische springen freiwillig aufs Brötchen."]'::jsonb, 0, 'Ist ein Preis zu hoch, suchen sich die Kunden ein günstigeres Angebot.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station7')::uuid, md5('taleria:stage1/hafen')::uuid, 7, 'game', true, 100, '{"title":"Wie viel ist viel?","place":"Marktplatz","goal":"Ein Gefühl für Preise bekommen","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Ich kaufe einfach alles! Das Eis, das Fahrrad und die Kinokarte!"},{"speaker":"talo","text":"Weißt du überhaupt, was das alles kostet?"},{"speaker":"tala","text":"Äh … nicht so genau."}],"lesson":[{"speaker":"talo","text":"Preise ungefähr zu kennen hilft. Dann merkst du, wenn etwas zu teuer ist."},{"speaker":"talo","text":"Ein Brötchen kostet viel weniger als eine Kinokarte. Und ein Fahrrad kostet ein Vielfaches davon."},{"speaker":"tala","text":"Ich schaue beim nächsten Einkauf mal ganz genau auf die Preisschilder!"},{"speaker":"talo","text":"Gute Idee. Preise ändern sich mit der Zeit und sind nicht überall gleich. Deshalb lohnt sich Vergleichen."}],"game":{"type":"estimate","title":"Preise schätzen","description":"Schätze Preise von Brötchen, Eis, Kinokarte, Fahrrad und Handy und sortiere sie von günstig bis teuer. Die Preisspannen müssen vor dem Start geprüft und regelmäßig aktualisiert werden."},"summary":{"speaker":"tala","text":"Wer Preise ungefähr kennt, kann besser planen und lässt sich nicht so leicht übers Ohr hauen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station7/q1')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Was ist meistens am günstigsten?', '["Ein Brötchen","Eine Kinokarte","Ein Fahrrad"]'::jsonb, 0, 'Ein Brötchen kostet viel weniger als eine Kinokarte oder ein Fahrrad.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station7/q2')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Was ist meistens am teuersten?', '["Ein neues Handy","Eine Kugel Eis","Ein Brötchen"]'::jsonb, 0, 'Ein neues Handy kostet ein Vielfaches von Eis oder Brötchen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station7/q3')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Wie findest du heraus, wie viel etwas ungefähr kostet?', '["Preisschilder anschauen und vergleichen","Raten und nie nachsehen","Den Hund fragen"]'::jsonb, 0, 'Wer Preise vergleicht, bekommt ein gutes Gefühl dafür.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station7/q4')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Warum lohnt es sich, Preise ungefähr zu kennen?', '["Man merkt schneller, wenn etwas zu teuer ist.","Dann wird alles kostenlos.","Dann muss man nie wieder einkaufen."]'::jsonb, 0, 'Ein Gefühl für Preise schützt vor teuren Fehlern.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station7/q5')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Sind Preise überall und immer gleich?', '["Nein, sie können sich je nach Laden und Zeit unterscheiden.","Ja, überall genau gleich","Nur montags"]'::jsonb, 0, 'Preise ändern sich und sind nicht in jedem Laden gleich. Vergleichen lohnt sich.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station7/q6')::uuid, md5('taleria:stage1/hafen/station7')::uuid, 'Tala will ein Eis, ein Fahrrad und eine Kinokarte auf einmal. Was sollte sie zuerst tun?', '["Herausfinden, was alles zusammen kostet","Alles sofort kaufen","Die Preisschilder abreißen"]'::jsonb, 0, 'Erst die Preise kennen, dann entscheiden, was drin ist.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/hafen/station8')::uuid, md5('taleria:stage1/hafen')::uuid, 8, 'exam', true, 150, '{"title":"Abschlussprüfung","place":"Hafenkontor","goal":"Alles vom Hafen wiederholen","minutes":"8 bis 10 Min.","scene":[{"speaker":"talo","text":"Zeit für die Abschlussprüfung! Ab 8 richtigen Antworten gehört das erste Kartenstück uns."},{"speaker":"tala","text":"Und wenn es nicht klappt, versuchen wir es einfach noch einmal. Ohne Strafe!"}],"summary":{"speaker":"tala","text":"Das erste Kartenstück! Auf zur Tauschinsel!"},"exam":{"show":10,"review":0,"pass":8}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q1')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum ist Geld praktischer als Tauschen?', '["Fast jeder nimmt es an.","Es ist leichter zu tragen als alles andere.","Es riecht besser."]'::jsonb, 0, 'Mit Geld muss man niemanden suchen, der genau das braucht, was man selbst hat.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q2')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was kann man mit Geld gut machen?', '["Es aufheben und später ausgeben","Es essen, wenn man Hunger hat","Es pflanzen, damit mehr wächst"]'::jsonb, 0, 'Geld kann man aufbewahren und später gegen etwas eintauschen.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q3')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum hat ein Geldschein einen Wert?', '["Weil alle ihn annehmen und darauf vertrauen","Weil er aus Gold ist","Weil er alt ist"]'::jsonb, 0, 'Der Wert entsteht, weil sich alle darauf verlassen.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q4')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Wie heißt unsere Währung?', '["Euro","Taler","Pfund"]'::jsonb, 0, 'In Deutschland bezahlen wir mit Euro.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q5')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum haben sich Münzen gegenüber Muscheln und Salz durchgesetzt?', '["Sie halten lange und lassen sich leicht zählen.","Sie schmecken besser.","Sie leuchten im Dunkeln."]'::jsonb, 0, 'Münzen gehen nicht kaputt, sind gleich groß und man kann sie gut abzählen.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q6')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was ist ein Vorteil von Scheinen gegenüber vielen Münzen?', '["Große Beträge sind leichter zu tragen.","Sie klimpern lauter.","Sie sind aus Gold."]'::jsonb, 0, 'Ein Schein ersetzt viele Münzen und passt in jede Tasche.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q7')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Womit bezahlen viele Menschen heute oft, ohne Münzen oder Scheine?', '["Mit Karte oder Handy","Mit Muscheln","Mit Salz"]'::jsonb, 0, 'Heute wird viel digital bezahlt, das Geld kommt dann vom Konto.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q8')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Wie viele Cent sind ein Euro?', '["100","10","1.000"]'::jsonb, 0, '100 Cent ergeben genau 1 Euro.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q9')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Wie viele verschiedene Euro-Münzen gibt es?', '["8","5","12"]'::jsonb, 0, 'Es gibt 1, 2, 5, 10, 20 und 50 Cent sowie 1 und 2 Euro.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q10')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Welcher ist der kleinste Euro-Schein?', '["5 Euro","1 Euro","10 Euro"]'::jsonb, 0, 'Den kleinsten Schein gibt es für 5 Euro, kleinere Beträge sind Münzen.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q11')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Wie legst du 3,50 Euro mit möglichst wenigen Münzen?', '["2 Euro, 1 Euro und 50 Cent","Sieben 50-Cent-Münzen","Drei 1-Euro-Münzen und fünf 10-Cent-Münzen"]'::jsonb, 0, 'Große Münzen zuerst nehmen, dann braucht man am wenigsten.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q12')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Du bezahlst 2 Euro für etwas, das 1,20 Euro kostet. Wie viel Wechselgeld bekommst du?', '["80 Cent","1 Euro","20 Cent"]'::jsonb, 0, '2 Euro minus 1,20 Euro sind 80 Cent.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q13')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Woher bekommen die meisten Erwachsenen ihr Geld?', '["Als Lohn für ihre Arbeit","Es wächst im Garten.","Sie finden es auf der Straße."]'::jsonb, 0, 'Wer arbeitet, bekommt dafür Lohn oder Gehalt.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q14')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum bekommen die Bootsbauer in der Werft Geld?', '["Weil sie für andere Schiffe reparieren","Weil sie lange schlafen","Weil sie Möwen füttern"]'::jsonb, 0, 'Geld bekommt man, weil man etwas leistet, das andere brauchen.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q15')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Darf man Euro-Geld einfach selbst drucken?', '["Nein, das ist verboten.","Ja, mit einem guten Drucker","Ja, aber nur am Wochenende"]'::jsonb, 0, 'Geld darf nur von bestimmten Stellen hergestellt werden, alles andere ist Falschgeld.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q16')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Woraus setzt sich der Preis eines Fischbrötchens zusammen?', '["Aus Zutaten, Miete, Lohn und Gewinn","Nur aus dem Fisch","Die Verkäuferin denkt sich einfach eine Zahl aus."]'::jsonb, 0, 'Ein Preis deckt alle Kosten und lässt einen kleinen Gewinn übrig.', 6, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q17')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was ist der Gewinn?', '["Das, was nach allen Kosten übrig bleibt","Das ganze Geld, das in die Kasse kommt","Das Trinkgeld"]'::jsonb, 0, 'Von den Einnahmen werden zuerst alle Kosten bezahlt, der Rest ist der Gewinn.', 6, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q18')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum ist ein Fischbrötchen am Hafen teurer als ein selbstgemachtes?', '["Weil Miete, Lohn und Gewinn dazukommen","Weil die Möwen mitessen","Weil Fisch am Hafen giftig ist"]'::jsonb, 0, 'Wer etwas verkauft, muss mehr verlangen als nur die Zutaten kosten.', 6, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q19')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Was kostet normalerweise am meisten?', '["Ein Fahrrad","Eine Kugel Eis","Ein Brötchen"]'::jsonb, 0, 'Ein Fahrrad kostet ein Vielfaches von Eis oder Brötchen.', 7, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/hafen/station8/q20')::uuid, md5('taleria:stage1/hafen/station8')::uuid, 'Warum hilft es, Preise ungefähr zu kennen?', '["Man merkt schneller, wenn etwas zu teuer ist.","Dann muss man nie wieder rechnen.","Dann wird alles billiger."]'::jsonb, 0, 'Wer Preise kennt, lässt sich nicht so leicht übers Ohr hauen.', 7, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

delete from public.quiz_questions q using public.stations s
where q.station_id = s.id and s.island_id = md5('taleria:stage1/hafen')::uuid
  and q.id not in (md5('taleria:stage1/hafen/station2/q1')::uuid, md5('taleria:stage1/hafen/station2/q2')::uuid, md5('taleria:stage1/hafen/station2/q3')::uuid, md5('taleria:stage1/hafen/station2/q4')::uuid, md5('taleria:stage1/hafen/station2/q5')::uuid, md5('taleria:stage1/hafen/station2/q6')::uuid, md5('taleria:stage1/hafen/station2/q7')::uuid, md5('taleria:stage1/hafen/station2/q8')::uuid, md5('taleria:stage1/hafen/station2/q9')::uuid, md5('taleria:stage1/hafen/station2/q10')::uuid, md5('taleria:stage1/hafen/station3/q1')::uuid, md5('taleria:stage1/hafen/station3/q2')::uuid, md5('taleria:stage1/hafen/station3/q3')::uuid, md5('taleria:stage1/hafen/station3/q4')::uuid, md5('taleria:stage1/hafen/station3/q5')::uuid, md5('taleria:stage1/hafen/station3/q6')::uuid, md5('taleria:stage1/hafen/station4/q1')::uuid, md5('taleria:stage1/hafen/station4/q2')::uuid, md5('taleria:stage1/hafen/station4/q3')::uuid, md5('taleria:stage1/hafen/station4/q4')::uuid, md5('taleria:stage1/hafen/station4/q5')::uuid, md5('taleria:stage1/hafen/station4/q6')::uuid, md5('taleria:stage1/hafen/station5/q1')::uuid, md5('taleria:stage1/hafen/station5/q2')::uuid, md5('taleria:stage1/hafen/station5/q3')::uuid, md5('taleria:stage1/hafen/station5/q4')::uuid, md5('taleria:stage1/hafen/station5/q5')::uuid, md5('taleria:stage1/hafen/station5/q6')::uuid, md5('taleria:stage1/hafen/station6/q1')::uuid, md5('taleria:stage1/hafen/station6/q2')::uuid, md5('taleria:stage1/hafen/station6/q3')::uuid, md5('taleria:stage1/hafen/station6/q4')::uuid, md5('taleria:stage1/hafen/station6/q5')::uuid, md5('taleria:stage1/hafen/station6/q6')::uuid, md5('taleria:stage1/hafen/station7/q1')::uuid, md5('taleria:stage1/hafen/station7/q2')::uuid, md5('taleria:stage1/hafen/station7/q3')::uuid, md5('taleria:stage1/hafen/station7/q4')::uuid, md5('taleria:stage1/hafen/station7/q5')::uuid, md5('taleria:stage1/hafen/station7/q6')::uuid, md5('taleria:stage1/hafen/station8/q1')::uuid, md5('taleria:stage1/hafen/station8/q2')::uuid, md5('taleria:stage1/hafen/station8/q3')::uuid, md5('taleria:stage1/hafen/station8/q4')::uuid, md5('taleria:stage1/hafen/station8/q5')::uuid, md5('taleria:stage1/hafen/station8/q6')::uuid, md5('taleria:stage1/hafen/station8/q7')::uuid, md5('taleria:stage1/hafen/station8/q8')::uuid, md5('taleria:stage1/hafen/station8/q9')::uuid, md5('taleria:stage1/hafen/station8/q10')::uuid, md5('taleria:stage1/hafen/station8/q11')::uuid, md5('taleria:stage1/hafen/station8/q12')::uuid, md5('taleria:stage1/hafen/station8/q13')::uuid, md5('taleria:stage1/hafen/station8/q14')::uuid, md5('taleria:stage1/hafen/station8/q15')::uuid, md5('taleria:stage1/hafen/station8/q16')::uuid, md5('taleria:stage1/hafen/station8/q17')::uuid, md5('taleria:stage1/hafen/station8/q18')::uuid, md5('taleria:stage1/hafen/station8/q19')::uuid, md5('taleria:stage1/hafen/station8/q20')::uuid);

insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/hafen/prompt1')::uuid, md5('taleria:stage1/hafen')::uuid, 'Was war das Erste, das du dir von deinem eigenen Geld gekauft hast? (Eltern erzählen)', 'draft')
on conflict (id) do update set text = excluded.text;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/hafen/prompt2')::uuid, md5('taleria:stage1/hafen')::uuid, 'Was glaubst du, wie viel unser Wocheneinkauf kostet?', 'draft')
on conflict (id) do update set text = excluded.text;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/hafen/prompt3')::uuid, md5('taleria:stage1/hafen')::uuid, 'Womit haben wir bezahlt, als ich so alt war wie du?', 'draft')
on conflict (id) do update set text = excluded.text;

-- 2. Tauschinsel
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/tauschinsel')::uuid, 'tauschinsel', 1, 1, 2, 0.28, 0.9, 'main', 'Tauschinsel', 'draft', '{"goal":"Das Kind erlebt, wie Tauschen ohne Geld funktioniert, versteht, dass Wert von Person und Situation abhängt, wie Angebot und Nachfrage Preise beeinflussen, dass billig nicht immer günstig ist, dass jede Entscheidung einen Verzicht bedeutet und was ein fairer Tausch ist.","access":"free","arrival":{"video_key":"video.arrival.tauschinsel","scene":[{"speaker":"talo","text":"Land in Sicht! Und unser Proviant ist fast leer."},{"speaker":"tala","text":"Drei Äpfel, bitte! Ich habe Taler!"},{"speaker":"bruno","text":"Taler? Was soll ich damit? Hier wird getauscht!","name":"Bruno"},{"speaker":"talo","text":"Dann müssen wir wohl lernen zu tauschen."},{"speaker":"olga","text":"Dieses Kartenstück bekommt nur, wer fair tauscht.","name":"Olga"}]},"badge":"Meistertauscher","real_life_task":{"title":"Fairer Tausch","text":"Tausche mit jemandem aus der Familie etwas (Buch, Spielzeug, Sammelkarte). Erzählt euch vorher gegenseitig, warum euch die Sachen etwas wert sind, und klärt, ob man zurücktauschen darf."}}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station1')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 1, 'game', true, 100, '{"title":"Hier gibt es kein Geld","place":"Anlegestelle","goal":"Tauschen klappt nur, wenn beide genau das wollen, was der andere hat","minutes":"6 bis 9 Min.","video_key":"video.station.tauschinsel.1","scene":[{"speaker":"tala","text":"Ich brauche ein neues Seil fürs Schiff. Ich bezahle mit Talern!"},{"speaker":"greta","text":"Taler? Hier wird getauscht. Für mein Seil will ich Äpfel.","name":"Greta"},{"speaker":"tala","text":"Äpfel hab ich keine …"},{"speaker":"talo","text":"Dann fragen wir herum, wer was braucht."}],"lesson":[{"speaker":"bruno","text":"Äpfel gebe ich gern her. Aber nur gegen Fisch!","name":"Bruno"},{"speaker":"otti","text":"Fisch habe ich. Ich hätte gern einen Eimer.","name":"Otti"},{"speaker":"tala","text":"Einen Eimer haben wir an Bord!"},{"speaker":"talo","text":"Also: Eimer gegen Fisch, Fisch gegen Äpfel, Äpfel gegen Seil. Das nennt man eine Tauschkette."},{"speaker":"tala","text":"Ganz schön viel Lauferei für ein Seil!"}],"game":{"type":"barter_chain","title":"Tauschkette","description":"Baue die Tauschkette: Eimer gegen Fisch, Fisch gegen Äpfel, Äpfel gegen Seil."},"summary":{"speaker":"talo","text":"Tauschen klappt nur, wenn beide genau das wollen, was der andere hat. Sonst braucht man eine lange Tauschkette."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station1/q1')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Warum braucht Tala auf der Tauschinsel eine Tauschkette?', '["Weil Greta etwas will, das Tala nicht direkt hat","Weil Ketten hübsch aussehen","Weil Talo es befohlen hat"]'::jsonb, 0, 'Will der andere nicht, was man hat, muss man über mehrere Tausche gehen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station1/q2')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Was ist der erste Tausch in Talas Kette?', '["Eimer gegen Fisch","Seil gegen Äpfel","Taler gegen Seil"]'::jsonb, 0, 'Otti will den Eimer und gibt dafür Fisch. Damit beginnt die Kette.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station1/q3')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Warum sind Talas Taler auf der Tauschinsel nichts wert?', '["Weil dort niemand Taler annimmt","Weil sie zu klein sind","Weil sie aus Schokolade sind"]'::jsonb, 0, 'Geld hat nur einen Wert, wenn andere es annehmen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station1/q4')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Was ist beim Tauschen ohne Geld oft das größte Problem?', '["Man muss jemanden finden, der genau das will, was man hat.","Man darf dabei nicht reden.","Tauschen ist verboten."]'::jsonb, 0, 'Beide Seiten müssen zueinander passen. Das ist selten.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station1/q5')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Wie viele Tausche braucht Tala für das Seil?', '["Drei","Einen","Zehn"]'::jsonb, 0, 'Eimer gegen Fisch, Fisch gegen Äpfel, Äpfel gegen Seil: drei Tausche.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station1/q6')::uuid, md5('taleria:stage1/tauschinsel/station1')::uuid, 'Wie wäre es mit Geld einfacher?', '["Tala könnte Greta direkt bezahlen.","Gar nicht","Dann bräuchte sie zwei Seile."]'::jsonb, 0, 'Mit Geld braucht man keine Tauschkette, weil fast jeder Geld annimmt.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station2')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 2, 'game', true, 100, '{"title":"Das große Tauschspiel","place":"Tauschmarkt","goal":"Vor einem Tausch überlegen: Was brauche ich, was gebe ich her?","minutes":"7 bis 10 Min.","scene":[{"speaker":"talo","text":"Heute Nacht wollen wir weitersegeln. Dafür brauchen wir eine Laterne."},{"speaker":"tala","text":"Ich habe eine Muschelkette, einen Korb und ein Stück Käse."},{"speaker":"bruno","text":"Eine Laterne findest du hier auf dem Markt. Aber nicht jeder tauscht gegen alles!","name":"Bruno"}],"lesson":[{"speaker":"talo","text":"Bevor du tauschst, frag dich: Was brauche ich wirklich? Und was gebe ich dafür her?"},{"speaker":"tala","text":"Manche Angebote klingen gut, sind es aber nicht. Drei Äpfel für meine schöne Kette? Nein danke!"},{"speaker":"talo","text":"Ein guter Tausch macht beide zufrieden. Und manchmal sagt man besser Nein."}],"game":{"type":"barter_rounds","title":"Tauschmarkt","description":"Starte mit drei Dingen und ertausche in mehreren Runden eine Laterne. Jeder Händler will etwas anderes, manche Angebote sind schlecht."},"summary":{"speaker":"tala","text":"Vor jedem Tausch nachdenken lohnt sich: Was brauche ich, und was gebe ich dafür her?"},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station2/q1')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Was solltest du vor einem Tausch klären?', '["Was ich brauche und was ich dafür hergebe","Wie das Wetter wird","Wer zuerst blinzelt"]'::jsonb, 0, 'Wer weiß, was er will, tauscht klüger.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station2/q2')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Ein Händler bietet dir eine kaputte Laterne gegen deinen besten Korb. Was tust du?', '["Ablehnen oder nachverhandeln","Sofort tauschen","Den Korb ins Meer werfen"]'::jsonb, 0, 'Man muss nicht jedes Angebot annehmen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station2/q3')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Woran erkennst du einen guten Tausch?', '["Beide sind am Ende zufrieden.","Einer hat den anderen ausgetrickst.","Es ging besonders schnell."]'::jsonb, 0, 'Ein guter Tausch ist für beide fair.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station2/q4')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Darf man bei einem Tausch Nein sagen?', '["Ja, immer","Nein, nie","Nur am Wochenende"]'::jsonb, 0, 'Ein Tausch ist freiwillig. Nein sagen ist erlaubt.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station2/q5')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Tala braucht eine Laterne. Welches Angebot hilft ihr am meisten?', '["Eine Laterne gegen ihren Korb","Drei Äpfel gegen ihre Kette","Ein Hut gegen ihren Käse"]'::jsonb, 0, 'Ein Tausch hilft, wenn man bekommt, was man wirklich braucht.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station2/q6')::uuid, md5('taleria:stage1/tauschinsel/station2')::uuid, 'Wann ist ein Tausch schlecht für dich?', '["Wenn du viel mehr hergibst, als du bekommst","Immer, Tauschen ist schlecht","Wenn die Laterne leuchtet"]'::jsonb, 0, 'Gibt man viel ab und bekommt wenig, lohnt sich der Tausch nicht.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station3')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 3, 'game', true, 100, '{"title":"Wert ist nicht für jeden gleich","place":"Quelle am Berg","goal":"Wert hängt von Person und Situation ab","minutes":"6 bis 9 Min.","video_key":"video.station.tauschinsel.3","scene":[{"speaker":"tala","text":"Puh, dieser Aufstieg! Ich habe so einen Durst!"},{"speaker":"talo","text":"Unten am Strand gab es überall Wasser. Hier oben wäre eine Flasche Wasser ein Schatz."},{"speaker":"tala","text":"Ich würde jetzt sogar mein Lieblings-Fischbrötchen gegen Wasser tauschen!"},{"speaker":"talo","text":"Ich mag Fischbrötchen gar nicht. Für mich wäre das kein guter Tausch."}],"lesson":[{"speaker":"talo","text":"Wie viel etwas wert ist, hängt von der Situation ab. Wasser ist oben am Berg in der Hitze mehr wert als unten an der Quelle."},{"speaker":"tala","text":"Und es hängt von der Person ab: Ich liebe Fischbrötchen, Talo nicht."},{"speaker":"talo","text":"Deshalb kann ein Tausch für beide gut sein: Jeder bekommt das, was ihm mehr wert ist."}],"game":{"type":"decision","title":"Was ist wem wie viel wert?","description":"Entscheide in verschiedenen Situationen, wem etwas wie viel wert ist."},"summary":{"speaker":"talo","text":"Wert ist nicht für jeden gleich. Er hängt von der Person und der Situation ab."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station3/q1')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Wann ist eine warme Jacke besonders viel wert?', '["An einem kalten Wintertag","Im Hochsommer am Strand","Wenn man schon zwei anhat"]'::jsonb, 0, 'Wer friert, schätzt eine Jacke viel mehr.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station3/q2')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Tala liebt Fischbrötchen, Talo nicht. Wer würde mehr dafür hergeben?', '["Tala","Talo","Beide gleich viel"]'::jsonb, 0, 'Wer etwas mag, ist bereit, mehr dafür zu geben.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station3/q3')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Warum kann ein Tausch für beide gut sein?', '["Weil jeder das bekommt, was ihm mehr wert ist","Weil einer immer verliert","Weil Tauschen immer Spaß macht"]'::jsonb, 0, 'Dinge sind für verschiedene Menschen unterschiedlich viel wert.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station3/q4')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Ein Sonnenschirm am Strand im Hochsommer ist …', '["viel wert, weil viele Schatten brauchen.","nichts wert.","nur nachts wertvoll."]'::jsonb, 0, 'Wenn viele etwas brauchen, steigt sein Wert.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station3/q5')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Was beeinflusst, wie viel dir etwas wert ist?', '["Was du magst und was du gerade brauchst","Nur die Farbe","Gar nichts"]'::jsonb, 0, 'Vorlieben und die Situation bestimmen den Wert.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station3/q6')::uuid, md5('taleria:stage1/tauschinsel/station3')::uuid, 'Otti sammelt Muscheln, Bruno sammelt Honigtöpfe. Was zeigt das?', '["Jeder findet andere Dinge wertvoll.","Muscheln sind wertlos.","Honig ist immer mehr wert als Muscheln."]'::jsonb, 0, 'Was jemand sammelt oder mag, ist für ihn besonders wertvoll.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station4')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 4, 'game', true, 100, '{"title":"Wenn alle Eis wollen","place":"Eisstand am Strand","goal":"Angebot und Nachfrage beeinflussen den Preis","minutes":"7 bis 10 Min.","scene":[{"speaker":"tala","text":"Darf ich heute den Eisstand übernehmen? Bitte, bitte!"},{"speaker":"talo","text":"Gern. Aber du bestimmst auch den Preis."},{"speaker":"tala","text":"Dann verlange ich ganz viel pro Kugel!"},{"speaker":"talo","text":"Mal sehen, wie viele Kunden dann kommen."}],"lesson":[{"speaker":"talo","text":"An heißen Tagen wollen viele ein Eis. Man sagt: Die Nachfrage ist groß."},{"speaker":"tala","text":"Und wenn das Eis knapp wird, zahlen manche sogar mehr dafür!"},{"speaker":"talo","text":"An Regentagen will kaum jemand Eis. Dann muss der Preis runter, sonst bleibt das Eis liegen."},{"speaker":"talo","text":"Angebot heißt: wie viel es von etwas gibt. Nachfrage heißt: wie viele es haben wollen. Beides beeinflusst den Preis."}],"game":{"type":"market_sim","title":"Eisstand","description":"Setze den Preis für dein Eis an heißen und an verregneten Tagen und sieh, wie viele Kunden kommen."},"summary":{"speaker":"tala","text":"Wollen viele etwas, das knapp ist, steigt der Preis. Will kaum jemand etwas, sinkt er."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station4/q1')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Es ist sehr heiß und alle wollen Eis. Wie nennt man das?', '["Große Nachfrage","Großes Angebot","Großen Hunger auf Suppe"]'::jsonb, 0, 'Nachfrage bedeutet, wie viele etwas haben wollen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station4/q2')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Der Eisstand hat nur noch wenig Eis, aber viele Kunden. Was passiert oft?', '["Der Preis steigt.","Das Eis wird verschenkt.","Der Stand schließt sofort."]'::jsonb, 0, 'Ist etwas knapp und begehrt, steigt meist der Preis.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station4/q3')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'An einem Regentag kommt kaum jemand zum Eisstand. Was ist klug?', '["Den Preis senken oder weniger Eis machen","Den Preis verdoppeln","Im Regen laut rufen, bis jemand kommt"]'::jsonb, 0, 'Bei wenig Nachfrage sinkt der Preis oder man bietet weniger an.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station4/q4')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Was bedeutet „Angebot“?', '["Wie viel von etwas zu haben ist","Wie viele etwas haben wollen","Ein besonders leckeres Eis"]'::jsonb, 0, 'Das Angebot ist die Menge, die es zu kaufen gibt.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station4/q5')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Warum sind manche Früchte zu bestimmten Jahreszeiten teurer?', '["Weil es dann weniger davon gibt","Weil sie dann größer sind","Weil sie dann verboten sind"]'::jsonb, 0, 'Gibt es weniger von etwas, wollen es aber genauso viele, wird es oft teurer.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station4/q6')::uuid, md5('taleria:stage1/tauschinsel/station4')::uuid, 'Tala verlangt für eine Kugel Eis einen sehr hohen Preis. Was passiert wahrscheinlich?', '["Weniger Kunden kaufen bei ihr.","Mehr Kunden kommen.","Das Eis schmilzt langsamer."]'::jsonb, 0, 'Ist der Preis zu hoch, kaufen viele lieber nicht oder woanders.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station5')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 5, 'game', true, 100, '{"title":"Preis und Qualität","place":"Werkstatt der Netzmacherin","goal":"Billig ist nicht immer günstig, vergleichen lohnt sich","minutes":"6 bis 9 Min.","video_key":"video.station.tauschinsel.5","scene":[{"speaker":"otti","text":"Mein Fischernetz ist schon wieder gerissen!","name":"Otti"},{"speaker":"greta","text":"Ich habe zwei Netze: eins für 5 Taler und eins für 20 Taler.","name":"Greta"},{"speaker":"otti","text":"Dann nehme ich natürlich das billige!","name":"Otti"},{"speaker":"greta","text":"Das billige hält aber nur einen Monat. Das teure ein ganzes Jahr.","name":"Greta"}],"lesson":[{"speaker":"talo","text":"Rechnen wir mal: Das billige Netz hält einen Monat. Für ein Jahr braucht Otti also 12 Stück."},{"speaker":"tala","text":"12 mal 5 Taler sind 60 Taler! Das gute Netz kostet nur 20."},{"speaker":"talo","text":"Billig ist also nicht immer günstig. Wer vergleicht, wie lange etwas hält, spart oft Geld."},{"speaker":"tala","text":"Aber teuer ist auch nicht automatisch gut. Vergleichen ist das Wichtigste!"}],"game":{"type":"calc","title":"Netz-Rechnung","description":"Rechne aus, welches Netz über ein Jahr günstiger ist."},"summary":{"speaker":"talo","text":"Billig ist nicht immer günstig. Vergleichen lohnt sich, auch wie lange etwas hält."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station5/q1')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Turnschuhe für 20 Taler halten ein halbes Jahr, Turnschuhe für 30 Taler ein ganzes Jahr. Was ist auf ein Jahr günstiger?', '["Die Turnschuhe für 30 Taler","Die Turnschuhe für 20 Taler","Beide kosten gleich viel"]'::jsonb, 0, 'Zwei billige Paare kosten 40 Taler, das gute Paar nur 30.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station5/q2')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Was solltest du beim Vergleichen außer dem Preis noch beachten?', '["Wie lange etwas hält","Wie laut es ist","Gar nichts"]'::jsonb, 0, 'Die Haltbarkeit gehört zum Vergleich dazu.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station5/q3')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Otti braucht im Jahr 12 Netze für je 5 Taler. Was kostet das?', '["60 Taler","17 Taler","5 Taler"]'::jsonb, 0, '12 mal 5 Taler sind 60 Taler.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station5/q4')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Ist etwas Teures immer besser?', '["Nein, vergleichen hilft.","Ja, immer","Nur bei Fischernetzen"]'::jsonb, 0, 'Ein hoher Preis allein sagt nicht, dass etwas gut ist.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station5/q5')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Was bedeutet „günstig“?', '["Für das, was man bekommt, nicht zu viel bezahlen","Immer das Billigste nehmen","Etwas, das glitzert"]'::jsonb, 0, 'Günstig heißt: Preis und Leistung passen gut zusammen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station5/q6')::uuid, md5('taleria:stage1/tauschinsel/station5')::uuid, 'Wie findest du heraus, ob sich etwas Teureres lohnt?', '["Vergleichen, wie lange es hält und was es kann","Würfeln","Den Verkäufer nach seiner Lieblingsfarbe fragen"]'::jsonb, 0, 'Wer vergleicht, entscheidet besser.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station6')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 6, 'game', true, 100, '{"title":"Was ist mir etwas wert?","place":"Aussichtsturm","goal":"Jede Entscheidung bedeutet einen Verzicht","minutes":"6 bis 9 Min.","video_key":"video.station.tauschinsel.6","scene":[{"speaker":"tala","text":"Oben auf dem Turm gibt es ein Fernrohr zu kaufen! Und unten den Eisstand."},{"speaker":"talo","text":"Du hast 5 Taler. Für beides reicht es nicht."},{"speaker":"tala","text":"Eis jetzt … oder sparen für das Fernrohr? Oh, ist das schwer!"}],"lesson":[{"speaker":"talo","text":"Geld kann man nur einmal ausgeben. Wer das Eis kauft, verzichtet aufs Sparen."},{"speaker":"tala","text":"Und wer spart, verzichtet heute aufs Eis, hat aber später das Fernrohr."},{"speaker":"talo","text":"Es gibt kein Richtig oder Falsch. Wichtig ist, dass du weißt, worauf du verzichtest."}],"game":{"type":"tradeoff","title":"Entscheidungen","description":"Triff mehrere Entscheidungen und sieh jedes Mal, worauf du verzichtest."},"summary":{"speaker":"tala","text":"Jede Entscheidung bedeutet einen Verzicht. Überleg dir, was dir wichtiger ist."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station6/q1')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Tala hat 5 Taler und kauft davon ein Eis für 5 Taler. Was kann sie danach nicht mehr?', '["Die 5 Taler fürs Fernrohr sparen","Das Eis essen","Auf den Turm steigen"]'::jsonb, 0, 'Geld kann man nur einmal ausgeben.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station6/q2')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Was bedeutet „verzichten“?', '["Etwas nicht nehmen, um etwas anderes zu bekommen","Alles gleichzeitig kaufen","Etwas verschenken, das man nicht mag"]'::jsonb, 0, 'Wer sich entscheidet, verzichtet auf die andere Möglichkeit.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station6/q3')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Was hilft bei einer Entscheidung zwischen zwei Wünschen?', '["Überlegen, was mir wichtiger ist","Immer das Teurere nehmen","Gar nicht entscheiden"]'::jsonb, 0, 'Wer weiß, was ihm wichtig ist, entscheidet leichter.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station6/q4')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Tala spart mehrere Wochen, statt Eis zu kaufen. Was bekommt sie dafür?', '["Später das Fernrohr","Gar nichts","Drei Eis gratis"]'::jsonb, 0, 'Wer heute verzichtet, kann sich später etwas Größeres leisten.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station6/q5')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Gibt es bei „Eis oder Fernrohr“ eine richtige Antwort für alle?', '["Nein, das hängt davon ab, was einem wichtiger ist.","Ja, immer das Eis","Ja, immer das Fernrohr"]'::jsonb, 0, 'Jeder entscheidet nach dem, was ihm wichtig ist.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station6/q6')::uuid, md5('taleria:stage1/tauschinsel/station6')::uuid, 'Warum kann man nicht alles haben, was man sich wünscht?', '["Weil das Geld nicht für alles reicht","Weil Wünsche verboten sind","Weil Läden nachts zuhaben"]'::jsonb, 0, 'Geld ist begrenzt. Deshalb muss man auswählen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station7')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 7, 'game', true, 100, '{"title":"Fair tauschen unter Freunden","place":"Strandlager bei Olga","goal":"Ein fairer Tausch: Beide wissen, was sie bekommen, und sind einverstanden","minutes":"7 bis 10 Min.","video_key":"video.station.tauschinsel.7","scene":[{"speaker":"olga","text":"Willkommen, junge Crew. Bevor ich euch das Kartenstück gebe, möchte ich etwas sehen.","name":"Olga"},{"speaker":"tala","text":"Was denn?"},{"speaker":"olga","text":"Ob ihr fair tauschen könnt. Auf dem Schulhof gibt es nämlich nicht nur faire Tausche.","name":"Olga"}],"lesson":[{"speaker":"talo","text":"Stell dir vor: Ein älteres Kind will einem jüngeren eine seltene Sammelkarte gegen eine ganz häufige abschwatzen."},{"speaker":"tala","text":"Das ist unfair! Das jüngere weiß gar nicht, wie selten seine Karte ist."},{"speaker":"talo","text":"Fair ist ein Tausch, wenn beide wissen, was sie bekommen, und beide einverstanden sind."},{"speaker":"olga","text":"Und wer vorher klärt, ob man zurücktauschen darf, hat später keinen Streit. Hier ist euer Kartenstück!","name":"Olga"}],"game":{"type":"situations","title":"Faire Tausche","description":"Erkenne faire und unfaire Tausche auf dem Schulhof und schlage faire vor. Am Ende tauscht die Crew fair mit Olga."},"summary":{"speaker":"talo","text":"Ein fairer Tausch: Beide wissen, was sie bekommen, und sind einverstanden."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station7/q1')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Wann ist ein Tausch fair?', '["Wenn beide wissen, was sie bekommen, und einverstanden sind","Wenn einer den anderen austrickst","Wenn es besonders schnell geht"]'::jsonb, 0, 'Fair heißt ehrlich und freiwillig.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station7/q2')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Ein älteres Kind will einem jüngeren eine seltene Karte gegen eine häufige abschwatzen. Ist das fair?', '["Nein, weil das jüngere den Wert nicht kennt","Ja, Tausch ist Tausch","Ja, weil Ältere immer recht haben"]'::jsonb, 0, 'Wer den anderen über den Wert im Unklaren lässt, tauscht nicht fair.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station7/q3')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Was solltet ihr vor einem Tausch absprechen?', '["Ob man zurücktauschen darf","Wer die schönere Jacke hat","Wie spät es ist"]'::jsonb, 0, 'Klare Absprachen verhindern späteren Streit.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station7/q4')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Dein Freund bietet dir einen unfairen Tausch an. Was kannst du tun?', '["Freundlich Nein sagen oder einen fairen Tausch vorschlagen","Ihn anschreien","Heimlich seine Karte nehmen"]'::jsonb, 0, 'Man kann Nein sagen und trotzdem freundlich bleiben.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station7/q5')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Warum gibt Olga der Crew das Kartenstück?', '["Weil die Crew fair getauscht hat","Weil Tala gebettelt hat","Weil Olga es loswerden wollte"]'::jsonb, 0, 'Olga wollte sehen, ob die Crew fair tauschen kann.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station7/q6')::uuid, md5('taleria:stage1/tauschinsel/station7')::uuid, 'Was gehört zu einem fairen Tausch?', '["Ehrlich sagen, wenn die eigene Sache einen Fehler hat","Fehler der eigenen Sache verschweigen","Den anderen unter Druck setzen"]'::jsonb, 0, 'Ehrlichkeit macht einen Tausch fair.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/tauschinsel/station8')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 8, 'exam', true, 150, '{"title":"Abschlussprüfung","place":"Strandlager bei Olga","goal":"Alles von der Tauschinsel wiederholen, dazu zwei Fragen aus dem Hafen","minutes":"8 bis 10 Min.","scene":[{"speaker":"olga","text":"Zeigt mir, was ihr gelernt habt. Ab 8 richtigen Antworten gehört das Kartenstück euch.","name":"Olga"},{"speaker":"tala","text":"Zwei Fragen kommen sogar noch aus dem Hafen. Weißt du noch?"}],"summary":{"speaker":"olga","text":"Klug und fair, so soll eine Crew sein. Gute Fahrt zur Wunschinsel!","name":"Olga"},"exam":{"show":8,"review":2,"pass":8}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q1')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Warum konnte Tala auf der Tauschinsel nicht mit Talern bezahlen?', '["Weil dort niemand Geld annimmt","Weil die Taler nass waren","Weil Talo sie versteckt hatte"]'::jsonb, 0, 'Geld funktioniert nur, wenn alle es annehmen.', 1, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q2')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Greta will Äpfel, Tala hat nur Fisch. Was kann Tala tun?', '["Erst Fisch gegen Äpfel tauschen, dann Äpfel gegen das Seil","Das Seil einfach mitnehmen","Sofort aufgeben"]'::jsonb, 0, 'Über eine Tauschkette kommt man auch ans Ziel, wenn es länger dauert.', 1, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q3')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was ist eine Tauschkette?', '["Mehrere Tausche hintereinander, bis man hat, was man braucht","Eine Halskette aus Gold","Ein Seil zum Festbinden"]'::jsonb, 0, 'Jeder Tausch ist ein Glied der Kette.', 1, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q4')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was solltest du dir vor einem Tausch überlegen?', '["Was ich wirklich brauche und was ich dafür hergebe","Welche Farbe der andere mag","Gar nichts, einfach schnell tauschen"]'::jsonb, 0, 'Wer vorher nachdenkt, macht bessere Tausche.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q5')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Woran erkennst du einen guten Tausch?', '["Am Ende sind beide zufrieden.","Nur einer hat gewonnen.","Einer ist traurig."]'::jsonb, 0, 'Ein guter Tausch ist für beide Seiten gut.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q6')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Wann ist eine Flasche Wasser besonders viel wert?', '["Nach einer langen Wanderung in der Hitze","Direkt nachdem man getrunken hat","Wenn man im Regen steht"]'::jsonb, 0, 'Der Wert hängt von der Situation ab.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q7')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Tala liebt Fischbrötchen, Talo mag sie nicht. Was zeigt das?', '["Dieselbe Sache ist nicht für jeden gleich viel wert.","Talo hat nie Hunger.","Fischbrötchen sind wertlos."]'::jsonb, 0, 'Jeder Mensch hat eigene Vorlieben, deshalb schätzt jeder Dinge anders.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q8')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Warum ist ein Regenschirm an einem Regentag mehr wert als bei Sonne?', '["Weil ihn dann viele brauchen","Weil er nass ist","Weil er dann größer wird"]'::jsonb, 0, 'Wenn viele etwas brauchen, wird es wertvoller.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q9')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Es ist heiß, alle wollen Eis, aber es gibt nur wenig. Was passiert oft mit dem Preis?', '["Er steigt.","Er sinkt.","Das Eis wird verschenkt."]'::jsonb, 0, 'Viele wollen etwas, das knapp ist: Dann steigt meist der Preis.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q10')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Im Winter will kaum jemand Eis. Was macht der Eisverkäufer wahrscheinlich?', '["Er senkt den Preis oder verkauft weniger.","Er verdoppelt den Preis.","Er verkauft nur noch Sand."]'::jsonb, 0, 'Wenig Nachfrage: Der Preis sinkt oder es wird weniger angeboten.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q11')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was bedeutet „Angebot“?', '["Wie viel von einer Sache zu haben ist","Wie freundlich ein Verkäufer ist","Ein Geschenk"]'::jsonb, 0, 'Das Angebot ist die Menge, die verkauft wird.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q12')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was bedeutet „Nachfrage“?', '["Wie viele etwas haben wollen","Wenn man zweimal nachfragt","Eine Quizfrage"]'::jsonb, 0, 'Die Nachfrage zeigt, wie begehrt etwas ist.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q13')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Ein Netz für 5 Taler hält einen Monat, eines für 20 Taler hält ein Jahr. Was ist auf ein Jahr gerechnet günstiger?', '["Das Netz für 20 Taler","Das Netz für 5 Taler","Beide kosten gleich viel"]'::jsonb, 0, '12 billige Netze kosten 60 Taler, das gute nur 20.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q14')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was bedeutet der Spruch „Wer billig kauft, kauft zweimal“?', '["Billige Dinge gehen manchmal schnell kaputt, dann muss man neu kaufen.","Man soll alles zweimal kaufen.","Billige Sachen sind immer schlecht."]'::jsonb, 0, 'Billig kann teuer werden. Aber nicht alles Billige ist schlecht, vergleichen hilft.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q15')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Ist das Teuerste immer das Beste?', '["Nein, man sollte vergleichen.","Ja, immer.","Ja, außer bei Eis."]'::jsonb, 0, 'Ein hoher Preis sagt noch nicht, dass etwas gut ist.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q16')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Tala hat 5 Taler: Eis jetzt oder sparen fürs Fernrohr. Was stimmt?', '["Kauft sie das Eis, verzichtet sie aufs Sparen.","Sie kann mit denselben 5 Talern beides haben.","Das spielt keine Rolle."]'::jsonb, 0, 'Geld kann man nur einmal ausgeben. Jede Entscheidung heißt Verzicht.', 6, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q17')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was hilft dir bei einer schwierigen Kaufentscheidung?', '["Überlegen, was mir wichtiger ist","Würfeln","Immer das Erste nehmen"]'::jsonb, 0, 'Wer weiß, was ihm wichtig ist, entscheidet leichter.', 6, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q18')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was ist ein fairer Tausch?', '["Beide wissen, was sie bekommen, und sind einverstanden.","Einer trickst den anderen aus.","Man nimmt dem Jüngeren etwas weg."]'::jsonb, 0, 'Fair heißt ehrlich und freiwillig.', 7, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q19')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Ein Freund will deine seltene Sammelkarte gegen eine ganz häufige tauschen. Was ist eine gute Reaktion?', '["Freundlich Nein sagen oder einen fairen Tausch vorschlagen","Sofort tauschen, damit er nicht sauer wird","Ihn auslachen"]'::jsonb, 0, 'Man darf Nein sagen und trotzdem freundlich bleiben.', 7, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/tauschinsel/station8/q20')::uuid, md5('taleria:stage1/tauschinsel/station8')::uuid, 'Was solltet ihr vor einem Tausch unter Freunden klären?', '["Ob man den Tausch später rückgängig machen darf","Wer schneller rennen kann","Welche Musik ihr hört"]'::jsonb, 0, 'Klare Absprachen verhindern Streit.', 7, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

delete from public.quiz_questions q using public.stations s
where q.station_id = s.id and s.island_id = md5('taleria:stage1/tauschinsel')::uuid
  and q.id not in (md5('taleria:stage1/tauschinsel/station1/q1')::uuid, md5('taleria:stage1/tauschinsel/station1/q2')::uuid, md5('taleria:stage1/tauschinsel/station1/q3')::uuid, md5('taleria:stage1/tauschinsel/station1/q4')::uuid, md5('taleria:stage1/tauschinsel/station1/q5')::uuid, md5('taleria:stage1/tauschinsel/station1/q6')::uuid, md5('taleria:stage1/tauschinsel/station2/q1')::uuid, md5('taleria:stage1/tauschinsel/station2/q2')::uuid, md5('taleria:stage1/tauschinsel/station2/q3')::uuid, md5('taleria:stage1/tauschinsel/station2/q4')::uuid, md5('taleria:stage1/tauschinsel/station2/q5')::uuid, md5('taleria:stage1/tauschinsel/station2/q6')::uuid, md5('taleria:stage1/tauschinsel/station3/q1')::uuid, md5('taleria:stage1/tauschinsel/station3/q2')::uuid, md5('taleria:stage1/tauschinsel/station3/q3')::uuid, md5('taleria:stage1/tauschinsel/station3/q4')::uuid, md5('taleria:stage1/tauschinsel/station3/q5')::uuid, md5('taleria:stage1/tauschinsel/station3/q6')::uuid, md5('taleria:stage1/tauschinsel/station4/q1')::uuid, md5('taleria:stage1/tauschinsel/station4/q2')::uuid, md5('taleria:stage1/tauschinsel/station4/q3')::uuid, md5('taleria:stage1/tauschinsel/station4/q4')::uuid, md5('taleria:stage1/tauschinsel/station4/q5')::uuid, md5('taleria:stage1/tauschinsel/station4/q6')::uuid, md5('taleria:stage1/tauschinsel/station5/q1')::uuid, md5('taleria:stage1/tauschinsel/station5/q2')::uuid, md5('taleria:stage1/tauschinsel/station5/q3')::uuid, md5('taleria:stage1/tauschinsel/station5/q4')::uuid, md5('taleria:stage1/tauschinsel/station5/q5')::uuid, md5('taleria:stage1/tauschinsel/station5/q6')::uuid, md5('taleria:stage1/tauschinsel/station6/q1')::uuid, md5('taleria:stage1/tauschinsel/station6/q2')::uuid, md5('taleria:stage1/tauschinsel/station6/q3')::uuid, md5('taleria:stage1/tauschinsel/station6/q4')::uuid, md5('taleria:stage1/tauschinsel/station6/q5')::uuid, md5('taleria:stage1/tauschinsel/station6/q6')::uuid, md5('taleria:stage1/tauschinsel/station7/q1')::uuid, md5('taleria:stage1/tauschinsel/station7/q2')::uuid, md5('taleria:stage1/tauschinsel/station7/q3')::uuid, md5('taleria:stage1/tauschinsel/station7/q4')::uuid, md5('taleria:stage1/tauschinsel/station7/q5')::uuid, md5('taleria:stage1/tauschinsel/station7/q6')::uuid, md5('taleria:stage1/tauschinsel/station8/q1')::uuid, md5('taleria:stage1/tauschinsel/station8/q2')::uuid, md5('taleria:stage1/tauschinsel/station8/q3')::uuid, md5('taleria:stage1/tauschinsel/station8/q4')::uuid, md5('taleria:stage1/tauschinsel/station8/q5')::uuid, md5('taleria:stage1/tauschinsel/station8/q6')::uuid, md5('taleria:stage1/tauschinsel/station8/q7')::uuid, md5('taleria:stage1/tauschinsel/station8/q8')::uuid, md5('taleria:stage1/tauschinsel/station8/q9')::uuid, md5('taleria:stage1/tauschinsel/station8/q10')::uuid, md5('taleria:stage1/tauschinsel/station8/q11')::uuid, md5('taleria:stage1/tauschinsel/station8/q12')::uuid, md5('taleria:stage1/tauschinsel/station8/q13')::uuid, md5('taleria:stage1/tauschinsel/station8/q14')::uuid, md5('taleria:stage1/tauschinsel/station8/q15')::uuid, md5('taleria:stage1/tauschinsel/station8/q16')::uuid, md5('taleria:stage1/tauschinsel/station8/q17')::uuid, md5('taleria:stage1/tauschinsel/station8/q18')::uuid, md5('taleria:stage1/tauschinsel/station8/q19')::uuid, md5('taleria:stage1/tauschinsel/station8/q20')::uuid);

insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/tauschinsel/prompt1')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 'Was hast du als Kind getauscht, und war es ein guter Tausch?', 'draft')
on conflict (id) do update set text = excluded.text;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/tauschinsel/prompt2')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 'Gibt es etwas, das dir viel wert ist, für andere aber kaum etwas?', 'draft')
on conflict (id) do update set text = excluded.text;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/tauschinsel/prompt3')::uuid, md5('taleria:stage1/tauschinsel')::uuid, 'Wann musstest du zuletzt auf etwas verzichten, um dir etwas anderes leisten zu können?', 'draft')
on conflict (id) do update set text = excluded.text;

-- 3. Wunschinsel
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/wunschinsel')::uuid, 'wunschinsel', 1, 1, 3, 0.72, 0.84, 'main', 'Wunschinsel', 'draft', '{"goal":"Das Kind unterscheidet Bedürfnisse und Wünsche, setzt Prioritäten, nutzt die Warte-Regel, erkennt Gruppendruck und weiß, dass Glück nicht nur von Dingen abhängt.","access":"premium","arrival":{"video_key":"video.arrival.wunschinsel","scene":[{"speaker":"tala","text":"Wow, hier glitzert und blinkt ja alles!"},{"speaker":"tala","text":"Das will ich! Und das! Und das!"},{"speaker":"elsa","text":"Alles zu haben, Schätzchen!","name":"Elsa"},{"speaker":"talo","text":"Moment. Was davon brauchst du wirklich?"},{"speaker":"talo","text":"Schau, im Wunschbrunnen leuchtet das nächste Kartenstück."}]},"badge":"Klarer Kompass","real_life_task":{"title":"Wunschflasche","text":"Steck einen Wunsch in die Wunschflasche und schau nach einer Woche mit deinen Eltern nach, ob du ihn noch willst."}}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station1')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 1, 'game', true, 100, '{"title":"Bedürfnis oder Wunsch","place":"Glitzerladen","goal":"Bedürfnisse kommen zuerst, Wünsche sind erlaubt","minutes":"6 bis 9 Min.","scene":[{"speaker":"elsa","text":"Willkommen im Glitzerladen! Alles glänzt, alles ist zu haben!","name":"Elsa"},{"speaker":"tala","text":"Das will ich! Und das! Und den Glitzerkompass!"},{"speaker":"talo","text":"Moment. Was davon brauchst du wirklich?"}],"lesson":[{"speaker":"talo","text":"Bedürfnisse sind Dinge, die man zum Leben braucht: Essen, Trinken, Kleidung und ein Zuhause."},{"speaker":"tala","text":"Und Wünsche sind Dinge, die Spaß machen, aber nicht lebensnotwendig sind. Wie mein Glitzerkompass!"},{"speaker":"talo","text":"Manche Dinge liegen dazwischen, zum Beispiel ein Handy. Es kommt darauf an, wofür man es braucht."},{"speaker":"tala","text":"Wünsche sind erlaubt! Aber Bedürfnisse kommen zuerst."}],"game":{"type":"sort","title":"Zwei Körbe","description":"Sortiere Dinge in den Korb für Bedürfnisse oder für Wünsche. Über Dinge dazwischen sprechen Talo und Tala."},"summary":{"speaker":"tala","text":"Bedürfnisse kommen zuerst, Wünsche sind erlaubt."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station1/q1')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Welches davon ist ein Bedürfnis?', '["Ein Dach über dem Kopf","Ein Glitzerkompass","Ein Videospiel"]'::jsonb, 0, 'Ein Zuhause braucht jeder zum Leben.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station1/q2')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Welches davon ist ein Wunsch?', '["Ein neues Spielzeug","Trinkwasser","Etwas zu essen"]'::jsonb, 0, 'Ein Spielzeug macht Freude, zum Leben braucht man es aber nicht.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station1/q3')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Was kommt zuerst, wenn das Geld knapp ist?', '["Die Bedürfnisse","Die Wünsche","Das, was am meisten glitzert"]'::jsonb, 0, 'Erst das Nötige, dann das Schöne.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station1/q4')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Sind Wünsche schlecht?', '["Nein, Wünsche sind erlaubt.","Ja, immer","Nur an Geburtstagen"]'::jsonb, 0, 'Wünsche sind in Ordnung, wenn die Bedürfnisse gedeckt sind.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station1/q5')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Warum ist ein Handy schwer einzuordnen?', '["Weil es je nach Situation Bedürfnis oder Wunsch sein kann","Weil es so klein ist","Weil es klingelt"]'::jsonb, 0, 'Für manche ist es nötig, etwa um die Eltern zu erreichen, für andere vor allem Spaß.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station1/q6')::uuid, md5('taleria:stage1/wunschinsel/station1')::uuid, 'Warme Winterstiefel im Dezember sind …', '["ein Bedürfnis.","ein Wunsch.","ein Spielzeug."]'::jsonb, 0, 'Im Winter braucht man warme Schuhe.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station2')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 2, 'game', true, 100, '{"title":"Prioritäten setzen","place":"Packhaus","goal":"Wenn das Geld nicht für alles reicht, entscheidet man nach Wichtigkeit","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Ich darf einen Rucksack für die Wanderung packen! Aber nur für 10 Taler."},{"speaker":"talo","text":"Und auf der Liste stehen Sachen für viel mehr als 10 Taler."},{"speaker":"tala","text":"Oh nein, ich will alles mitnehmen!"}],"lesson":[{"speaker":"talo","text":"Wenn das Geld nicht für alles reicht, muss man auswählen."},{"speaker":"talo","text":"Prioritäten setzen heißt: Das Wichtigste kommt zuerst in den Rucksack."},{"speaker":"tala","text":"Also erst Wasser und Proviant, dann vielleicht die Glitzersonnenbrille."},{"speaker":"talo","text":"Und wer sich für etwas entscheidet, verzichtet auf etwas anderes."}],"game":{"type":"pack","title":"Rucksack packen","description":"Packe Talas Rucksack mit 10 Talern. Das Wichtigste zuerst."},"summary":{"speaker":"talo","text":"Reicht das Geld nicht für alles, entscheidet man nach Wichtigkeit."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station2/q1')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Du hast 10 Taler. Wasser kostet 2, Proviant 4, eine Glitzerbrille 6. Was packst du für eine Wanderung ein?', '["Wasser und Proviant","Nur die Glitzerbrille","Alles, auch wenn das Geld nicht reicht"]'::jsonb, 0, 'Wasser und Proviant kosten zusammen 6 Taler und sind am wichtigsten. Für die Brille reicht es dann nicht mehr.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station2/q2')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Was bedeutet „Prioritäten setzen“?', '["Das Wichtigste zuerst","Das Teuerste zuerst","Alles auf einmal"]'::jsonb, 0, 'Prioritäten zeigen, was am wichtigsten ist.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station2/q3')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Warum muss man manchmal auswählen?', '["Weil das Geld nicht für alles reicht","Weil Rucksäcke böse sind","Weil Auswählen Pflicht ist"]'::jsonb, 0, 'Geld ist begrenzt, Wünsche sind es oft nicht.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station2/q4')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Tala packt die Glitzerbrille statt Proviant ein. Was ist das Problem?', '["Auf der Wanderung fehlt ihr etwas Wichtiges.","Es gibt kein Problem.","Die Brille ist zu dunkel."]'::jsonb, 0, 'Wer Unwichtiges zuerst kauft, hat für Wichtiges kein Geld mehr.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station2/q5')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Wie kannst du deine Wünsche ordnen?', '["Nach Wichtigkeit, das Wichtigste oben","Nach Farbe","Nach dem Alphabet"]'::jsonb, 0, 'Eine Reihenfolge nach Wichtigkeit hilft beim Entscheiden.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station2/q6')::uuid, md5('taleria:stage1/wunschinsel/station2')::uuid, 'Wenn du dich für einen Wunsch entscheidest, …', '["verzichtest du auf einen anderen.","bekommst du alle anderen gratis.","bleibt das Geld trotzdem da."]'::jsonb, 0, 'Geld kann man nur einmal ausgeben.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station3')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 3, 'game', true, 100, '{"title":"Die Warte-Regel","place":"Wunschflaschen-Strand","goal":"Warten zeigt, ob man etwas wirklich will","minutes":"6 bis 9 Min.","video_key":"video.station.wunschinsel.3","scene":[{"speaker":"tala","text":"Den Glitzerkompass kaufe ich sofort! Jetzt gleich!"},{"speaker":"talo","text":"Warte mal. Kennst du die Warte-Regel?"},{"speaker":"tala","text":"Die Warte-was?"}],"lesson":[{"speaker":"talo","text":"Bei kleinen Wünschen schläfst du eine Nacht drüber. Bei großen eine ganze Woche."},{"speaker":"tala","text":"Und wenn ich es danach immer noch will?"},{"speaker":"talo","text":"Dann ist es ein echter Wunsch. Viele Wünsche sind nach ein paar Tagen aber einfach verschwunden."},{"speaker":"tala","text":"Ich stecke meinen Wunsch in eine Wunschflasche! Dann fragt mich die App später, ob ich ihn noch will."}],"game":{"type":"wish_bottle","title":"Wunschflasche","description":"Steck einen eigenen Wunsch in eine Wunschflasche. Die App fragt später nach, ob du ihn noch willst."},"summary":{"speaker":"talo","text":"Warten zeigt, ob man etwas wirklich will."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station3/q1')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Was sagt die Warte-Regel?', '["Vor einem Kauf erst drüber schlafen","Immer sofort kaufen","Nie etwas kaufen"]'::jsonb, 0, 'Mit etwas Abstand entscheidet man besser.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station3/q2')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Wie lange wartest du ungefähr bei einem kleinen Wunsch?', '["Eine Nacht","Ein Jahr","Eine Sekunde"]'::jsonb, 0, 'Bei kleinen Wünschen reicht eine Nacht.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station3/q3')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Wie lange wartest du ungefähr bei einem großen Wunsch?', '["Eine Woche","Gar nicht","Eine Minute"]'::jsonb, 0, 'Je größer der Wunsch, desto länger lohnt sich das Überlegen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station3/q4')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Was passiert oft mit Wünschen, wenn man wartet?', '["Manche verschwinden von selbst.","Sie werden doppelt so groß.","Sie werden automatisch billiger."]'::jsonb, 0, 'Viele Wünsche sind nach ein paar Tagen gar nicht mehr wichtig.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station3/q5')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Tala will den Kompass nach einer Woche immer noch. Was bedeutet das?', '["Es ist ein echter Wunsch.","Sie hat die Regel falsch gemacht.","Der Kompass ist kaputt."]'::jsonb, 0, 'Bleibt der Wunsch, kann man überlegen, dafür zu sparen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station3/q6')::uuid, md5('taleria:stage1/wunschinsel/station3')::uuid, 'Wozu ist die Wunschflasche gut?', '["Um einen Wunsch aufzuschreiben und später noch einmal zu prüfen","Um Limonade zu trinken","Um Wünsche ins Meer zu werfen"]'::jsonb, 0, 'Die Wunschflasche hilft beim Warten.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station4')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 4, 'game', true, 100, '{"title":"Alle haben das","place":"Möwenplatz","goal":"Gruppendruck erkennen und Nein sagen können","minutes":"6 bis 9 Min.","video_key":"video.station.wunschinsel.4","scene":[{"speaker":"tala","text":"Guck mal, alle Möwen tragen rote Mützen! Ich brauche auch eine!"},{"speaker":"talo","text":"Brauchst du sie wirklich, oder willst du nur dazugehören?"},{"speaker":"tala","text":"Hmm … gestern wollte ich noch gar keine."}],"lesson":[{"speaker":"talo","text":"Wenn man etwas tut, weil alle anderen es tun oder erwarten, nennt man das Gruppendruck."},{"speaker":"tala","text":"Gruppendruck kann dazu führen, dass man Sachen kauft, die man eigentlich gar nicht will."},{"speaker":"talo","text":"Eine gute Frage ist: Würde ich das auch wollen, wenn es niemand sonst hätte?"},{"speaker":"tala","text":"Und man darf freundlich Nein sagen. Das ist sogar ziemlich stark!"}],"game":{"type":"situations","title":"Gruppendruck erkennen","description":"Erkenne Situationen mit Gruppendruck und übe Antworten."},"summary":{"speaker":"tala","text":"Gruppendruck erkennen und Nein sagen können, das macht stark."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station4/q1')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Alle in der Klasse haben dieselben Turnschuhe. Welche Frage hilft dir?', '["Würde ich sie auch wollen, wenn sie niemand hätte?","Wie bekomme ich drei Paar?","Wer hat die teuersten?"]'::jsonb, 0, 'Diese Frage zeigt, ob man etwas wirklich will.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station4/q2')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Was ist Gruppendruck?', '["Wenn man etwas tut, weil andere es erwarten","Wenn eine Gruppe Druckbuchstaben schreibt","Wenn es im Bus eng ist"]'::jsonb, 0, 'Gruppendruck kann zu Entscheidungen führen, die man eigentlich nicht will.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station4/q3')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Was ist eine gute Antwort, wenn dich jemand drängt, etwas zu kaufen?', '["„Nein danke, das brauche ich nicht.“","„Ich kaufe gleich zwei!“","Gar nichts sagen und sofort kaufen"]'::jsonb, 0, 'Ein freundliches Nein ist stark.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station4/q4')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Warum wollte Tala plötzlich eine rote Mütze?', '["Weil alle Möwen eine trugen","Weil ihr kalt war","Weil rote Mützen schneller machen"]'::jsonb, 0, 'Sie wollte dazugehören, nicht weil sie die Mütze brauchte.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station4/q5')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Ist es schlimm, nicht alles zu haben, was andere haben?', '["Nein, jeder darf eigene Entscheidungen treffen.","Ja, sehr schlimm","Ja, dann darf man nicht mitspielen"]'::jsonb, 0, 'Echte Freunde mögen dich wegen dir, nicht wegen deiner Sachen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station4/q6')::uuid, md5('taleria:stage1/wunschinsel/station4')::uuid, 'Woran merkst du, dass du unter Gruppendruck stehst?', '["Du willst etwas nur, weil andere es haben.","Du hast Hunger.","Es regnet."]'::jsonb, 0, 'Kommt der Wunsch nur von den anderen, ist das Gruppendruck.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station5')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 5, 'game', true, 100, '{"title":"Macht Geld glücklich?","place":"Moritz'' Höhle","goal":"Geld hilft, aber Glück hat viele Quellen","minutes":"6 bis 9 Min.","video_key":"video.station.wunschinsel.5","scene":[{"speaker":"moritz","text":"Kommt rein, kommt rein! Viel habe ich nicht, aber es ist gemütlich.","name":"Moritz"},{"speaker":"tala","text":"Du hast ja fast gar nichts! Bist du nicht traurig?"},{"speaker":"moritz","text":"Traurig? Ich habe meine Freunde, meine Sonnenplätze und meine Murmelsammlung. Ich bin sehr zufrieden.","name":"Moritz"}],"lesson":[{"speaker":"talo","text":"Geld ist wichtig. Es kann Sorgen nehmen, zum Beispiel um Essen oder ein Zuhause."},{"speaker":"tala","text":"Aber die Freude über neue Sachen hält oft nicht lange. Mein Glitzerkompass wäre nach einer Woche bestimmt ganz normal."},{"speaker":"talo","text":"Freunde, gemeinsame Zeit und Gesundheit machen auch glücklich. Die kann man nicht kaufen."}],"game":{"type":"conversation","title":"Gespräch mit Moritz","description":"Unterhalte dich mit Moritz darüber, was ihn glücklich macht."},"summary":{"speaker":"talo","text":"Geld hilft, aber Glück hat viele Quellen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station5/q1')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Wobei kann Geld helfen?', '["Es kann Sorgen nehmen, zum Beispiel ums Essen.","Es kann Freunde kaufen.","Es macht immer glücklich."]'::jsonb, 0, 'Geld hilft bei vielen Dingen, aber nicht bei allem.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station5/q2')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Warum ist Moritz zufrieden, obwohl er wenig besitzt?', '["Weil er Freunde und schöne Zeit hat","Weil er heimlich reich ist","Weil er den ganzen Tag schläft"]'::jsonb, 0, 'Glück hängt nicht nur vom Besitz ab.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station5/q3')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Was passiert oft mit der Freude über etwas Neues?', '["Sie wird mit der Zeit kleiner.","Sie wird jeden Tag größer.","Sie bleibt für immer gleich."]'::jsonb, 0, 'Man gewöhnt sich schnell an Neues.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station5/q4')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Was kann man nicht kaufen?', '["Echte Freundschaft","Ein Eis","Einen Ball"]'::jsonb, 0, 'Freundschaft entsteht durch Zeit und Vertrauen, nicht durch Geld.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station5/q5')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Welcher Satz stimmt?', '["Geld ist wichtig, aber nicht das Einzige, was glücklich macht.","Nur Geld macht glücklich.","Geld ist völlig unwichtig."]'::jsonb, 0, 'Geld und Glück hängen zusammen, aber nicht nur.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station5/q6')::uuid, md5('taleria:stage1/wunschinsel/station5')::uuid, 'Was macht viele Menschen glücklich?', '["Zeit mit Familie und Freunden","Möglichst viele Kassenbons","Allein Geld zählen"]'::jsonb, 0, 'Gemeinsame Zeit gehört für viele zu den schönsten Dingen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station6')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 6, 'game', true, 100, '{"title":"Erlebnisse statt Dinge","place":"Erinnerungsfelsen","goal":"Erlebnisse bleiben oft länger in Erinnerung","minutes":"6 bis 9 Min.","scene":[{"speaker":"tala","text":"Was ist das für ein Felsen? Da sind überall Bilder eingeritzt!"},{"speaker":"talo","text":"Das ist der Erinnerungsfelsen. Hier halten die Inselbewohner ihre schönsten Erlebnisse fest."},{"speaker":"tala","text":"Kein einziges Bild von einem Spielzeug. Nur Ausflüge, Feste und Freunde!"}],"lesson":[{"speaker":"talo","text":"Ein neues Spielzeug ist toll, aber oft liegt es nach ein paar Wochen in der Ecke."},{"speaker":"tala","text":"An einen schönen Ausflug erinnere ich mich noch lange. Wie an unsere erste Fahrt mit dem Schiff!"},{"speaker":"talo","text":"Erlebnisse teilt man mit anderen. Und viele schöne Erlebnisse kosten kaum Geld."}],"game":{"type":"album","title":"Erinnerungs-Album","description":"Vergleiche ein neues Spielzeug mit einem gemeinsamen Ausflug und gestalte ein kleines Album schöner Erlebnisse."},"summary":{"speaker":"tala","text":"Erlebnisse bleiben oft länger in Erinnerung als Dinge."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station6/q1')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Was bleibt oft länger in Erinnerung?', '["Ein Tag am See mit Freunden","Ein neuer Radiergummi","Eine Werbeanzeige"]'::jsonb, 0, 'Gemeinsame Erlebnisse bleiben lange im Gedächtnis.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station6/q2')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Warum sind Erlebnisse oft besonders wertvoll?', '["Man teilt sie mit anderen und erinnert sich gern daran.","Weil sie immer teuer sind","Weil man sie im Schrank aufbewahren kann"]'::jsonb, 0, 'Erinnerungen verbinden Menschen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station6/q3')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Was kostet oft kaum Geld und macht trotzdem Freude?', '["Ein Picknick im Park","Ein neues Handy","Eine Fernreise"]'::jsonb, 0, 'Viele schöne Erlebnisse kosten wenig.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station6/q4')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Was passiert oft mit neuen Spielsachen nach einiger Zeit?', '["Man spielt seltener damit.","Sie werden immer spannender.","Sie verwandeln sich in Gold."]'::jsonb, 0, 'Neues wird schnell normal.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station6/q5')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Wofür ist ein Erinnerungs-Album gut?', '["Um schöne Erlebnisse festzuhalten","Um Rechnungen zu sammeln","Um Hausaufgaben zu verstecken"]'::jsonb, 0, 'Ein Album hilft, sich an Schönes zu erinnern.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station6/q6')::uuid, md5('taleria:stage1/wunschinsel/station6')::uuid, 'Du hast 20 Taler: neues Spielzeug oder Ausflug mit Freunden. Was stimmt?', '["Beides ist in Ordnung, aber der Ausflug bleibt oft länger in Erinnerung.","Nur das Spielzeug ist vernünftig.","Ausflüge sind verboten."]'::jsonb, 0, 'Es ist deine Entscheidung. Erlebnisse halten aber oft länger.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station7')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 7, 'game', true, 100, '{"title":"Meine Wunschliste","place":"Wunschbrunnen","goal":"Eine gute Wunschliste hilft beim Planen","minutes":"7 bis 10 Min.","video_key":"video.station.wunschinsel.7","scene":[{"speaker":"tala","text":"Da ist der Wunschbrunnen! Und unten leuchtet das Kartenstück!"},{"speaker":"elsa","text":"Das Kartenstück erscheint nur, wenn man eine kluge Wunschliste hineinwirft.","name":"Elsa"},{"speaker":"tala","text":"Eine kluge Wunschliste? Ich schreibe einfach alles auf!"},{"speaker":"talo","text":"Klug heißt: mit Preisen und nach Wichtigkeit sortiert."}],"lesson":[{"speaker":"talo","text":"Schreib deine Wünsche auf und schätze, was sie ungefähr kosten."},{"speaker":"tala","text":"Dann sortiere ich: Was ist mir am wichtigsten? Das kommt nach oben."},{"speaker":"talo","text":"Für den wichtigsten Wunsch kannst du einen Wunschschatz anlegen und dafür sparen."},{"speaker":"elsa","text":"Oh, eine kluge Liste! Seht nur, das Kartenstück steigt auf!","name":"Elsa"}],"game":{"type":"wish_list","title":"Wunschliste","description":"Schreibe eine Wunschliste mit Preisen, sortiere sie nach Wichtigkeit und übernimm einen Wunsch als Wunschschatz."},"summary":{"speaker":"talo","text":"Eine gute Wunschliste hilft beim Planen."},"quiz":{"show":3}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station7/q1')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Was gehört auf eine kluge Wunschliste?', '["Wünsche mit ungefähren Preisen, sortiert nach Wichtigkeit","Alles aus der Werbung","Nur die teuersten Sachen"]'::jsonb, 0, 'So sieht man, was man sich leisten kann und was zuerst kommt.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station7/q2')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Warum schreibt man die Preise dazu?', '["Damit man sieht, wie viel man sparen muss","Weil Zahlen hübsch aussehen","Damit die Liste länger wird"]'::jsonb, 0, 'Mit Preisen kann man planen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station7/q3')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Welcher Wunsch kommt auf der Liste nach oben?', '["Der, der mir am wichtigsten ist","Der, der am teuersten ist","Der, den meine Freunde haben"]'::jsonb, 0, 'Die Reihenfolge zeigt deine Prioritäten.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station7/q4')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Was kannst du mit deinem wichtigsten Wunsch machen?', '["Einen Wunschschatz anlegen und dafür sparen","Ihn sofort vergessen","Ihn heimlich kaufen"]'::jsonb, 0, 'Ein Wunschschatz macht aus einem Wunsch ein Ziel.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station7/q5')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Tala wünscht sich ein Fernrohr für 30 Taler und legt jede Woche 5 Taler zur Seite. Wie viele Wochen muss sie sparen?', '["6 Wochen","3 Wochen","30 Wochen"]'::jsonb, 0, '30 Taler geteilt durch 5 Taler pro Woche sind 6 Wochen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station7/q6')::uuid, md5('taleria:stage1/wunschinsel/station7')::uuid, 'Warum ist eine Wunschliste besser, als alles sofort zu kaufen?', '["Man denkt nach und gibt Geld für das Wichtigste aus.","Weil Listen immer Spaß machen","Weil man dann nichts mehr bekommt"]'::jsonb, 0, 'Planen hilft, das eigene Geld klug einzusetzen.', null, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

insert into public.stations (id, island_id, sort_order, type, is_required, xp_reward, content, status)
values (md5('taleria:stage1/wunschinsel/station8')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 8, 'exam', true, 150, '{"title":"Abschlussprüfung","place":"Wunschbrunnen","goal":"Alles von der Wunschinsel wiederholen, dazu zwei Fragen von früheren Inseln","minutes":"8 bis 10 Min.","scene":[{"speaker":"talo","text":"Letzte Prüfung auf der Wunschinsel. Ab 8 richtigen Antworten steigt das Kartenstück aus dem Brunnen."},{"speaker":"tala","text":"Ich wünsche mir … dass wir bestehen! Und das ist ein echter Wunsch, kein Glitzerkram."}],"summary":{"speaker":"tala","text":"Geschafft! Das Kartenstück ist unser. Auf zur nächsten Insel!"},"exam":{"show":8,"review":2,"pass":8}}'::jsonb, 'draft')
on conflict (id) do update set
  sort_order = excluded.sort_order, type = excluded.type, xp_reward = excluded.xp_reward,
  content = excluded.content;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q1')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was ist ein Bedürfnis?', '["Etwas, das man zum Leben braucht","Etwas, das gerade alle haben","Etwas, das glitzert"]'::jsonb, 0, 'Essen, Trinken, Kleidung und ein Zuhause sind Bedürfnisse.', 1, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q2')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was ist ein Wunsch und kein Bedürfnis?', '["Eine neue Spielkonsole","Trinkwasser","Eine warme Jacke im Winter"]'::jsonb, 0, 'Eine Konsole macht Spaß, zum Leben braucht man sie nicht.', 1, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q3')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum ist es wichtig, Bedürfnisse und Wünsche zu unterscheiden?', '["Damit zuerst das Wichtige bezahlt wird","Damit man nie etwas Schönes kauft","Weil Wünsche verboten sind"]'::jsonb, 0, 'Wünsche sind in Ordnung, Bedürfnisse kommen zuerst.', 1, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q4')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Ist ein Handy ein Bedürfnis oder ein Wunsch?', '["Das kommt auf die Situation an.","Immer ein Bedürfnis wie Wasser","Immer nur ein Wunsch"]'::jsonb, 0, 'Manche Dinge liegen dazwischen.', 1, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q5')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Du hast 10 Taler und drei Wünsche für je 6 Taler. Was tust du?', '["Den wichtigsten auswählen","Alle drei kaufen","Gar nicht nachdenken"]'::jsonb, 0, '10 Taler reichen nur für einen.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q6')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was heißt „Prioritäten setzen“?', '["Entscheiden, was am wichtigsten ist","Alles gleichzeitig machen","Immer das Billigste kaufen"]'::jsonb, 0, 'Wer Prioritäten setzt, gibt sein Geld für das Wichtigste aus.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q7')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Wenn du dich für einen Wunsch entscheidest, …', '["verzichtest du auf einen anderen.","bekommst du alle anderen gratis.","ist das Geld danach noch da."]'::jsonb, 0, 'Geld kann man nur einmal ausgeben.', 2, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q8')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was besagt die Warte-Regel?', '["Vor einem Kauf erst drüber schlafen","Immer sofort kaufen","Nur nachts einkaufen"]'::jsonb, 0, 'Mit etwas Abstand entscheidet man besser.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q9')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum hilft Warten vor einem Kauf?', '["Man merkt, ob man es wirklich will.","Die Sachen werden beim Warten billiger.","Man vergisst, wo der Laden ist."]'::jsonb, 0, 'Viele Wünsche verschwinden nach ein paar Tagen von selbst.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q10')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Wie lange wartet man bei großen Wünschen?', '["Länger, zum Beispiel eine Woche","Gar nicht","Eine Minute"]'::jsonb, 0, 'Je teurer, desto länger lohnt sich das Überlegen.', 3, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q11')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Alle in deiner Klasse haben eine bestimmte Trinkflasche. Welche Frage hilft dir?', '["Brauche ich sie wirklich oder will ich nur dazugehören?","Wie bekomme ich zwei davon?","Wer hat die teuerste?"]'::jsonb, 0, 'Diese Frage hilft gegen Gruppendruck.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q12')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was ist Gruppendruck?', '["Wenn man etwas tut, weil andere es erwarten","Wenn eine Gruppe ein Foto macht","Druck im Ohr beim Tauchen"]'::jsonb, 0, 'Gruppendruck kann zu Käufen führen, die man gar nicht will.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q13')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Wie kannst du auf Gruppendruck reagieren?', '["Ruhig sagen, dass du es nicht brauchst","Sofort alles nachkaufen","Die anderen auslachen"]'::jsonb, 0, 'Freundlich Nein sagen ist stark.', 4, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q14')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was stimmt über Geld und Glück?', '["Geld kann Sorgen nehmen, aber Freunde und Zeit machen auch glücklich.","Wer am meisten Geld hat, ist immer am glücklichsten.","Geld macht immer unglücklich."]'::jsonb, 0, 'Glück hat viele Quellen.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q15')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum hält die Freude über ein neues Spielzeug oft nicht lange?', '["Weil man sich schnell daran gewöhnt","Weil Spielzeug verboten ist","Weil es nachts verschwindet"]'::jsonb, 0, 'Neues wird schnell normal.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q16')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was macht Moritz glücklich, obwohl er wenig besitzt?', '["Seine Freunde und die Zeit mit ihnen","Ein riesiger Goldschatz","Ein teures Handy"]'::jsonb, 0, 'Moritz zeigt, dass Glück nicht vom Besitz abhängt.', 5, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q17')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was bleibt oft länger in Erinnerung?', '["Ein gemeinsamer Ausflug","Ein neues Paar Socken","Ein Kassenbon"]'::jsonb, 0, 'Erlebnisse teilt man und erinnert sich gern daran.', 6, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q18')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Warum können Erlebnisse mehr wert sein als Dinge?', '["Man erinnert sich gern daran und teilt sie mit anderen.","Weil Erlebnisse immer gratis sind","Weil Dinge immer kaputtgehen"]'::jsonb, 0, 'Erinnerungen bleiben, auch wenn Dinge alt werden.', 6, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q19')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Was gehört auf eine gute Wunschliste?', '["Wünsche mit Preis, sortiert nach Wichtigkeit","Alles, was in der Werbung kommt","Nur Sachen von Freunden"]'::jsonb, 0, 'So sieht man, was man sich leisten kann.', 7, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;
insert into public.quiz_questions (id, station_id, question, answers, correct_index, explanation, covers_station, status)
values (md5('taleria:stage1/wunschinsel/station8/q20')::uuid, md5('taleria:stage1/wunschinsel/station8')::uuid, 'Du wünschst dir ein Fahrrad für 120 Taler. Was ist der erste kluge Schritt?', '["Einen Wunschschatz anlegen und einen Sparplan überlegen","Es sofort kaufen, ohne Geld zu haben","Den Wunsch vergessen"]'::jsonb, 0, 'Mit einem Plan wird aus einem Wunsch ein Ziel.', 7, 'draft')
on conflict (id) do update set
  question = excluded.question, answers = excluded.answers, correct_index = excluded.correct_index,
  explanation = excluded.explanation, covers_station = excluded.covers_station;

delete from public.quiz_questions q using public.stations s
where q.station_id = s.id and s.island_id = md5('taleria:stage1/wunschinsel')::uuid
  and q.id not in (md5('taleria:stage1/wunschinsel/station1/q1')::uuid, md5('taleria:stage1/wunschinsel/station1/q2')::uuid, md5('taleria:stage1/wunschinsel/station1/q3')::uuid, md5('taleria:stage1/wunschinsel/station1/q4')::uuid, md5('taleria:stage1/wunschinsel/station1/q5')::uuid, md5('taleria:stage1/wunschinsel/station1/q6')::uuid, md5('taleria:stage1/wunschinsel/station2/q1')::uuid, md5('taleria:stage1/wunschinsel/station2/q2')::uuid, md5('taleria:stage1/wunschinsel/station2/q3')::uuid, md5('taleria:stage1/wunschinsel/station2/q4')::uuid, md5('taleria:stage1/wunschinsel/station2/q5')::uuid, md5('taleria:stage1/wunschinsel/station2/q6')::uuid, md5('taleria:stage1/wunschinsel/station3/q1')::uuid, md5('taleria:stage1/wunschinsel/station3/q2')::uuid, md5('taleria:stage1/wunschinsel/station3/q3')::uuid, md5('taleria:stage1/wunschinsel/station3/q4')::uuid, md5('taleria:stage1/wunschinsel/station3/q5')::uuid, md5('taleria:stage1/wunschinsel/station3/q6')::uuid, md5('taleria:stage1/wunschinsel/station4/q1')::uuid, md5('taleria:stage1/wunschinsel/station4/q2')::uuid, md5('taleria:stage1/wunschinsel/station4/q3')::uuid, md5('taleria:stage1/wunschinsel/station4/q4')::uuid, md5('taleria:stage1/wunschinsel/station4/q5')::uuid, md5('taleria:stage1/wunschinsel/station4/q6')::uuid, md5('taleria:stage1/wunschinsel/station5/q1')::uuid, md5('taleria:stage1/wunschinsel/station5/q2')::uuid, md5('taleria:stage1/wunschinsel/station5/q3')::uuid, md5('taleria:stage1/wunschinsel/station5/q4')::uuid, md5('taleria:stage1/wunschinsel/station5/q5')::uuid, md5('taleria:stage1/wunschinsel/station5/q6')::uuid, md5('taleria:stage1/wunschinsel/station6/q1')::uuid, md5('taleria:stage1/wunschinsel/station6/q2')::uuid, md5('taleria:stage1/wunschinsel/station6/q3')::uuid, md5('taleria:stage1/wunschinsel/station6/q4')::uuid, md5('taleria:stage1/wunschinsel/station6/q5')::uuid, md5('taleria:stage1/wunschinsel/station6/q6')::uuid, md5('taleria:stage1/wunschinsel/station7/q1')::uuid, md5('taleria:stage1/wunschinsel/station7/q2')::uuid, md5('taleria:stage1/wunschinsel/station7/q3')::uuid, md5('taleria:stage1/wunschinsel/station7/q4')::uuid, md5('taleria:stage1/wunschinsel/station7/q5')::uuid, md5('taleria:stage1/wunschinsel/station7/q6')::uuid, md5('taleria:stage1/wunschinsel/station8/q1')::uuid, md5('taleria:stage1/wunschinsel/station8/q2')::uuid, md5('taleria:stage1/wunschinsel/station8/q3')::uuid, md5('taleria:stage1/wunschinsel/station8/q4')::uuid, md5('taleria:stage1/wunschinsel/station8/q5')::uuid, md5('taleria:stage1/wunschinsel/station8/q6')::uuid, md5('taleria:stage1/wunschinsel/station8/q7')::uuid, md5('taleria:stage1/wunschinsel/station8/q8')::uuid, md5('taleria:stage1/wunschinsel/station8/q9')::uuid, md5('taleria:stage1/wunschinsel/station8/q10')::uuid, md5('taleria:stage1/wunschinsel/station8/q11')::uuid, md5('taleria:stage1/wunschinsel/station8/q12')::uuid, md5('taleria:stage1/wunschinsel/station8/q13')::uuid, md5('taleria:stage1/wunschinsel/station8/q14')::uuid, md5('taleria:stage1/wunschinsel/station8/q15')::uuid, md5('taleria:stage1/wunschinsel/station8/q16')::uuid, md5('taleria:stage1/wunschinsel/station8/q17')::uuid, md5('taleria:stage1/wunschinsel/station8/q18')::uuid, md5('taleria:stage1/wunschinsel/station8/q19')::uuid, md5('taleria:stage1/wunschinsel/station8/q20')::uuid);

insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/wunschinsel/prompt1')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 'Was hast du dir mal sehr gewünscht und dann kaum benutzt?', 'draft')
on conflict (id) do update set text = excluded.text;
insert into public.conversation_prompts (id, island_id, text, status)
values (md5('taleria:stage1/wunschinsel/prompt2')::uuid, md5('taleria:stage1/wunschinsel')::uuid, 'Was war dein schönstes Erlebnis, das fast kein Geld gekostet hat?', 'draft')
on conflict (id) do update set text = excluded.text;

-- 4. Spar-Insel (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/spar-insel')::uuid, 'spar-insel', 1, 1, 4, 0.5, 0.765, 'main', 'Spar-Insel', 'draft', '{"goal":"Sparen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 5. Taschengeld-Bucht (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/taschengeld-bucht')::uuid, 'taschengeld-bucht', 1, 2, 5, 0.28, 0.7, 'main', 'Taschengeld-Bucht', 'draft', '{"goal":"Taschengeld einteilen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 6. Marktinsel (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/marktinsel')::uuid, 'marktinsel', 1, 2, 6, 0.72, 0.635, 'main', 'Marktinsel', 'draft', '{"goal":"Einkaufen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 7. Werbe-Riff (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/werbe-riff')::uuid, 'werbe-riff', 1, 2, 7, 0.5, 0.57, 'main', 'Werbe-Riff', 'draft', '{"goal":"Werbung durchschauen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 8. Verdienst-Insel (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/verdienst-insel')::uuid, 'verdienst-insel', 1, 2, 8, 0.28, 0.505, 'main', 'Verdienst-Insel', 'draft', '{"goal":"Geld verdienen","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 9. Bank-Insel (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/bank-insel')::uuid, 'bank-insel', 1, 3, 9, 0.72, 0.44, 'main', 'Bank-Insel', 'draft', '{"goal":"Bank und Konto","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 10. Zins-Insel (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/zins-insel')::uuid, 'zins-insel', 1, 3, 10, 0.5, 0.375, 'main', 'Zins-Insel', 'draft', '{"goal":"Zinsen und Inflation","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 11. Leih-Lagune (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/leih-lagune')::uuid, 'leih-lagune', 1, 3, 11, 0.28, 0.31, 'main', 'Leih-Lagune', 'draft', '{"goal":"Leihen und Schulden","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 12. Sicherheits-Festung (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/sicherheits-festung')::uuid, 'sicherheits-festung', 1, 3, 12, 0.72, 0.245, 'main', 'Sicherheits-Festung', 'draft', '{"goal":"Sicher mit Geld","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 13. Risiko-Klippen (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/risiko-klippen')::uuid, 'risiko-klippen', 1, 4, 13, 0.5, 0.18, 'main', 'Risiko-Klippen', 'draft', '{"goal":"Risiko und Vorsorge","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 14. Zukunftsinsel (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/zukunftsinsel')::uuid, 'zukunftsinsel', 1, 4, 14, 0.28, 0.115, 'main', 'Zukunftsinsel', 'draft', '{"goal":"Planen und Investieren als Idee","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

-- 15. Schatzinsel (Nebel)
insert into public.islands (id, slug, stage, island_group, sort_order, map_x, map_y, route_type, title, status, content)
values (md5('taleria:stage1/schatzinsel')::uuid, 'schatzinsel', 1, 4, 15, 0.72, 0.05, 'main', 'Schatzinsel', 'draft', '{"goal":"Abschluss und Goldene Schatzkarte","access":"premium"}'::jsonb)
on conflict (id) do update set
  slug = excluded.slug, island_group = excluded.island_group, sort_order = excluded.sort_order,
  map_x = excluded.map_x, map_y = excluded.map_y, title = excluded.title, content = excluded.content;

commit;
