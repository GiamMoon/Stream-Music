-- ACTUALIZACIÓN 2.2: Cambiar MP3 por HLS (URLs de prueba de Bitmovin/Apple)
UPDATE tracks 
SET stream_url = 'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8'
WHERE title = 'Blinding Lights';

UPDATE tracks 
SET stream_url = 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8'
WHERE title = 'Levitating';

-- ACTUALIZACIÓN 3.3: Crear Tabla de Letras
CREATE TABLE IF NOT EXISTS lyrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    track_id UUID REFERENCES tracks(id),
    time_ms INT NOT NULL, -- Tiempo en milisegundos
    text TEXT NOT NULL
);

-- Insertar Letras para "Blinding Lights" (ID temporal, lo ajustaremos con una subquery)
INSERT INTO lyrics (track_id, time_ms, text)
SELECT id, 10000, 'I''ve been tryna call' FROM tracks WHERE title = 'Blinding Lights' UNION ALL
SELECT id, 13000, 'I''ve been on my own for long enough' FROM tracks WHERE title = 'Blinding Lights' UNION ALL
SELECT id, 18000, 'Maybe you can show me how to love, maybe' FROM tracks WHERE title = 'Blinding Lights' UNION ALL
SELECT id, 25000, 'I''m going through withdrawals' FROM tracks WHERE title = 'Blinding Lights';