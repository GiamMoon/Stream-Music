-- 1. Insertar Artistas (Simulamos datos reales de Spotify)
INSERT INTO artists (id, name, bio, image_url, popularity) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'The Weeknd', 'Estrella del R&B alternativo.', 'https://i.scdn.co/image/ab6761610000e5eb214f3cf1cbe7139c1e26ffbb', 99),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'Dua Lipa', 'Icono del Pop moderno.', 'https://i.scdn.co/image/ab6761610000e5eb9e690225e0735f5242d547f3', 95),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'Bad Bunny', 'Rey del Trap Latino.', 'https://i.scdn.co/image/ab6761610000e5eb80370d235c5c4e704618a381', 100);

-- 2. Insertar Álbumes
INSERT INTO albums (id, title, artist_id, cover_url, release_date, label) VALUES
('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', 'After Hours', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'https://upload.wikimedia.org/wikipedia/en/c/c1/The_Weeknd_-_After_Hours.png', '2020-03-20', 'XO / Republic'),
('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', 'Future Nostalgia', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'https://upload.wikimedia.org/wikipedia/en/f/f5/Dua_Lipa_-_Levitating.png', '2020-03-27', 'Warner Records');

-- 3. Insertar Canciones (Tracks)
-- NOTA: Usamos URLs de prueba públicas para el audio (MP3) y video (MP4)
INSERT INTO tracks (id, title, artist_id, album_id, duration_ms, stream_url, canvas_url, has_lyrics, is_explicit) VALUES
(
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c11', 
    'Blinding Lights', 
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', 
    200000, 
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 
    'https://assets.mixkit.co/videos/preview/mixkit-stars-in-space-background-1602-large.mp4', 
    TRUE, 
    FALSE
),
(
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c12', 
    'Levitating', 
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', 
    203000, 
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', 
    NULL, 
    FALSE, 
    FALSE
);