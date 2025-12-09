-- 1. Limpieza previa (Evita duplicados de intentos anteriores)
TRUNCATE TABLE tracks CASCADE;
TRUNCATE TABLE albums CASCADE;

-- 2. Insertar Álbumes
INSERT INTO albums (title, artist_id, cover_url, release_date, label)
SELECT 'Un Verano Sin Ti', id, 'https://resources.tidal.com/images/860038f2/c3e1/4df6/a62e/ead97285672e/750x750.jpg', '2022-05-06', 'Rimas'
FROM artists WHERE name = 'Bad Bunny';

INSERT INTO albums (title, artist_id, cover_url, release_date, label)
SELECT 'After Hours', id, 'https://resources.tidal.com/images/5598dc62/acf6/49f1/b468/192ad3555278/750x750.jpg', '2020-03-20', 'XO / Republic'
FROM artists WHERE name = 'The Weeknd';

-- CORRECCIÓN AQUÍ: Quitamos el punto y coma que sobraba
INSERT INTO albums (title, artist_id, cover_url, release_date, label)
SELECT 'Future Nostalgia', id, 'https://resources.tidal.com/images/28047130/6ada/4955/b3b9/65bed4508618/750x750.jpg', '2020-03-27', 'Warner'
FROM artists WHERE name = 'Dua Lipa';

-- 3. Insertar Canciones (Tracks)
-- CORRECCIÓN: Agregamos canvas_url explícitamente como cadena vacía '' si no hay video, para que Go no falle.

-- TRACK 1: Bad Bunny
INSERT INTO tracks (title, artist_id, album_id, duration_ms, stream_url, canvas_url, has_lyrics, is_explicit)
SELECT 'Moscow Mule', a.id, al.id, 245000, 'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8', '', true, true
FROM artists a, albums al
WHERE a.name = 'Bad Bunny' AND al.title = 'Un Verano Sin Ti';

-- TRACK 2: The Weeknd
INSERT INTO tracks (title, artist_id, album_id, duration_ms, stream_url, canvas_url, has_lyrics, is_explicit)
SELECT 'Blinding Lights', a.id, al.id, 200000, 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8', 'https://assets.mixkit.co/videos/preview/mixkit-stars-in-space-background-1602-large.mp4', true, false
FROM artists a, albums al
WHERE a.name = 'The Weeknd' AND al.title = 'After Hours';

-- TRACK 3: Dua Lipa
INSERT INTO tracks (title, artist_id, album_id, duration_ms, stream_url, canvas_url, has_lyrics, is_explicit)
SELECT 'Levitating', a.id, al.id, 203000, 'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8', '', true, false
FROM artists a, albums al
WHERE a.name = 'Dua Lipa' AND al.title = 'Future Nostalgia';