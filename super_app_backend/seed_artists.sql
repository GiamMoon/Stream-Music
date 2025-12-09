-- 1. Limpiar la tabla de artistas
-- Usamos CASCADE para que borre automáticamente cualquier álbum/canción vieja vinculada
-- y así evitar errores de IDs duplicados o huérfanos.
TRUNCATE TABLE artists CASCADE;

-- 2. Insertar la nueva lista VIP
INSERT INTO artists (name, image_url, popularity) VALUES
('Michael Jackson', 'https://resources.tidal.com/images/4eb3fd31/d6b7/4162/8fcc/c9a4ebee85d2/750x750.jpg', 100),
('Bad Bunny', 'https://resources.tidal.com/images/860038f2/c3e1/4df6/a62e/ead97285672e/750x750.jpg', 99),
('Taylor Swift', 'https://resources.tidal.com/images/ffa46767/8d63/42bd/9dc7/827881ef460c/750x750.jpg', 98),
('The Weeknd', 'https://resources.tidal.com/images/5598dc62/acf6/49f1/b468/192ad3555278/750x750.jpg', 97),
('Drake', 'https://resources.tidal.com/images/3812d980/630e/4948/a72e/f21a546ec2e3/750x750.jpg', 96),
('Shakira', 'https://resources.tidal.com/images/11eced9f/ff93/4d4c/8808/04f0a59498f2/750x750.jpg', 95),
('Karol G', 'https://resources.tidal.com/images/c92a05dd/0e4b/4728/beff/2547b55b5cea/750x750.jpg', 94),
('Dua Lipa', 'https://resources.tidal.com/images/28047130/6ada/4955/b3b9/65bed4508618/750x750.jpg', 93),
('Rosalía', 'https://resources.tidal.com/images/651b15da/d8ce/4dee/a05a/0eeca2b4999b/750x750.jpg', 92),
('Coldplay', 'https://resources.tidal.com/images/b4579672/5b91/4679/a27a/288f097a4da5/750x750.jpg', 91),
('Post Malone', 'https://resources.tidal.com/images/039dedb4/2e50/41df/ae8f/54ad371a31f3/750x750.jpg', 90),
('Arcangel', 'https://resources.tidal.com/images/4925910d/2576/42ec/9157/e3c8ea0ac3d1/750x750.jpg', 89),
('Arctic Monkeys', 'https://resources.tidal.com/images/c63cfc4e/e779/4c21/afd1/381cde8f43c2/750x750.jpg', 88),
('Billie Eilish', 'https://resources.tidal.com/images/b2a74265/ad7f/4e14/b170/cc31e0ed8a4e/750x750.jpg', 87);