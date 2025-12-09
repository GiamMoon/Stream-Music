-- Habilitar extensión para generar UUIDs (IDs únicos y seguros)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Usuarios (Req 1.1)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Aquí guardaremos el hash de Argon2
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Artistas (Req 1.2)
CREATE TABLE artists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    bio TEXT,
    image_url TEXT,
    popularity INT DEFAULT 0 -- Para ayudar al algoritmo de recomendación
);

-- 3. Álbumes
CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(150) NOT NULL,
    artist_id UUID REFERENCES artists(id),
    cover_url TEXT,
    release_date DATE,
    label VARCHAR(100) -- Para Req 3.4 (Fuente/Sello)
);

-- 4. Canciones / Tracks (El núcleo - Req 2.2, 2.4, 3.x)
CREATE TABLE tracks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(150) NOT NULL,
    artist_id UUID REFERENCES artists(id),
    album_id UUID REFERENCES albums(id),
    duration_ms INT NOT NULL,
    
    -- URLs de Streaming y Media
    stream_url TEXT NOT NULL, -- URL base del .m3u8
    canvas_url TEXT,          -- URL del video loop (Req 2.4)
    cover_url TEXT,           -- Puede ser diferente a la del álbum
    
    -- Flags Técnicos
    has_lyrics BOOLEAN DEFAULT FALSE,
    is_explicit BOOLEAN DEFAULT FALSE,
    available_qualities TEXT[], -- Array ej: ['AAC_64', 'AAC_320', 'FLAC'] (Req 2.2)
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Créditos Extendidos (Req 3.4)
-- Relación 1 a 1 con Tracks, o almacenado aquí para consultas rápidas
CREATE TABLE track_credits (
    track_id UUID REFERENCES tracks(id) PRIMARY KEY,
    producers TEXT[],
    writers TEXT[],
    engineers TEXT[]
);

-- 6. Selección Inicial de Gustos (Req 1.2)
-- Guardamos qué artistas eligió el usuario en el onboarding
CREATE TABLE user_favorite_artists (
    user_id UUID REFERENCES users(id),
    artist_id UUID REFERENCES artists(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, artist_id)
);

-- 7. Playlists (Req 1.3)
CREATE TABLE playlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id), -- Dueño de la playlist
    name VARCHAR(100),
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE
);

CREATE TABLE playlist_tracks (
    playlist_id UUID REFERENCES playlists(id),
    track_id UUID REFERENCES tracks(id),
    position INT, -- Para mantener el orden de la mezcla
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (playlist_id, track_id)
);