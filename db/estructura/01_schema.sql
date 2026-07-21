-- =====================================================
-- ESQUEMA FÍSICO: SISTEMA RAG DOCUMENTAL
-- Base de Datos: PostgreSQL + pgvector
-- =====================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- Tabla de Áreas
CREATE TABLE areas (
    area_id SERIAL PRIMARY KEY,
    nombre_area VARCHAR(100) NOT NULL,
    codigo_interno VARCHAR(20) UNIQUE NOT NULL
);

-- Tabla de Usuarios
CREATE TABLE usuarios (
    usuario_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    area_id INT NOT NULL REFERENCES areas(area_id),
    nivel_acceso VARCHAR(50) NOT NULL DEFAULT 'Tecnico_Basico'
);

-- Tabla de Categorías de Documentos
CREATE TABLE categorias (
    categoria_id SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- Tabla de Documentos
CREATE TABLE documentos (
    documento_id SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    estado VARCHAR(20) CHECK (estado IN ('vigente', 'en_revision', 'archivado')) DEFAULT 'vigente',
    nivel_acceso_requerido VARCHAR(50) NOT NULL,
    area_id INT NOT NULL REFERENCES areas(area_id),
    categoria_id INT REFERENCES categorias(categoria_id)
);

-- Tabla de Versiones
CREATE TABLE versiones_documento (
    version_id SERIAL PRIMARY KEY,
    documento_id INT NOT NULL REFERENCES documentos(documento_id),
    numero_version VARCHAR(20) NOT NULL,
    fecha_publicacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    url_archivo_origen VARCHAR(500) NOT NULL,
    es_activa BOOLEAN DEFAULT true
);

-- Tabla de Fragmentos (Chunks)
CREATE TABLE fragmentos (
    fragmento_id SERIAL PRIMARY KEY,
    version_id INT NOT NULL REFERENCES versiones_documento(version_id),
    numero_secuencia INT NOT NULL,
    contenido_texto TEXT NOT NULL,
    embedding vector(1536), -- Vector para modelos OpenAI/Llama
    metadatos JSONB
);

-- Tabla de Consultas RAG
CREATE TABLE consultas_rag (
    consulta_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES usuarios(usuario_id),
    pregunta_texto TEXT NOT NULL,
    respuesta_ia TEXT NOT NULL,
    fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla Intermedia para Fuentes (Trazabilidad M:N)
CREATE TABLE fuentes_consulta (
    consulta_id INT REFERENCES consultas_rag(consulta_id) ON DELETE CASCADE,
    fragmento_id INT REFERENCES fragmentos(fragmento_id),
    score_similitud FLOAT NOT NULL,
    PRIMARY KEY (consulta_id, fragmento_id)
);
