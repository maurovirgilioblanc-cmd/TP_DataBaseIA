-- Índice vectorial HNSW para distancia coseno
CREATE INDEX idx_fragmentos_embedding_hnsw 
ON fragmentos 
USING hnsw (embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- Índice GIN sobre metadatos JSONB
CREATE INDEX idx_fragmentos_metadatos_gin 
ON fragmentos 
USING gin (metadatos);

-- Índice de soporte para Joins
CREATE INDEX idx_documentos_area_estado 
ON documentos (area_id, estado);
