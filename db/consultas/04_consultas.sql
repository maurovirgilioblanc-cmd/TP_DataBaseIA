-- =====================================================
-- CONSULTAS REPRESENTATIVAS PARA EVALUACIÓN
-- =====================================================
-- ==============================================================================
-- 1. BÚSQUEDA VECTORIAL HÍBRIDA RAG (Similitud Coseno + Seguridad + Vigencia)
-- ==============================================================================
-- Nota: Usamos el operador <=> de pgvector para distancia coseno.
-- Pasamos un vector dummy de prueba para simular la búsqueda del prompt.
SELECT 
    f.fragmento_id,
    d.titulo AS documento_titulo,
    v.url_archivo_origen,
    f.contenido_texto,
    f.metadatos->>'pagina_pdf' AS pagina,
    1 - (f.embedding <=> array_fill(0.01, ARRAY[1536])::vector) AS similitud_coseno
FROM fragmentos f
JOIN versiones_documento v ON f.version_id = v.version_id
JOIN documentos d ON v.documento_id = d.documento_id
JOIN usuarios u ON u.usuario_id = 1
WHERE v.es_activa = TRUE 
  AND d.estado = 'vigente'
  AND d.area_id = u.area_id
ORDER BY f.embedding <=> array_fill(0.01, ARRAY[1536])::vector
LIMIT 5;


-- ==============================================================================
-- 2. AUDITORÍA Y TRAZABILIDAD (Historial RAG con fuentes y scores)
-- ==============================================================================
SELECT 
    c.consulta_id,
    c.pregunta_texto,
    c.respuesta_ia,
    d.titulo AS documento_fuente,
    v.url_archivo_origen,
    fc.score_similitud
FROM consultas_rag c
JOIN fuentes_consulta fc ON c.consulta_id = fc.consulta_id
JOIN fragmentos f ON fc.fragmento_id = f.fragmento_id
JOIN versiones_documento v ON f.version_id = v.version_id
JOIN documentos d ON v.documento_id = d.documento_id
ORDER BY c.fecha_consulta DESC;


-- ==============================================================================
-- 3. MÉTRICAS Y ANALYTICS (Top documentos citados en los últimos 30 días)
-- ==============================================================================
SELECT 
    d.documento_id,
    d.titulo AS documento_titulo,
    COUNT(fc.fuente_id) AS total_citas
FROM consultas_rag c
JOIN fuentes_consulta fc ON c.consulta_id = fc.consulta_id
JOIN fragmentos f ON fc.fragmento_id = f.fragmento_id
JOIN versiones_documento v ON f.version_id = v.version_id
JOIN documentos d ON v.documento_id = d.documento_id
WHERE c.fecha_consulta >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY d.documento_id, d.titulo
ORDER BY total_citas DESC;


-- ==============================================================================
-- 4. CONTROL DE OBSOLECENCIA E INTEGRIDAD (Detección de fragmentos en versiones no activas/archivadas)
-- ==============================================================================
SELECT 
    f.fragmento_id,
    d.titulo AS documento_titulo,
    d.estado AS estado_documento,
    v.numero_version,
    v.es_activa
FROM fragmentos f
JOIN versiones_documento v ON f.version_id = v.version_id
JOIN documentos d ON v.documento_id = d.documento_id
WHERE v.es_activa = FALSE 
   OR d.estado IN ('archivado', 'obsoleto', 'dado_de_baja');


-- ==============================================================================
-- 5. OPTIMIZACIÓN E ÍNDICES (EXPLAIN ANALYZE para validar HNSW y B-Tree)
-- ==============================================================================
-- Ejecutá esto para ver cómo el motor de Postgres utiliza el índice vectorial HNSW y los B-Tree.
EXPLAIN ANALYZE
SELECT 
    f.fragmento_id,
    f.contenido_texto,
    1 - (f.embedding <=> array_fill(0.01, ARRAY[1536])::vector) AS similitud
FROM fragmentos f
JOIN versiones_documento v ON f.version_id = v.version_id
JOIN documentos d ON v.documento_id = d.documento_id
WHERE v.es_activa = TRUE 
  AND d.estado = 'vigente'
ORDER BY f.embedding <=> array_fill(0.01, ARRAY[1536])::vector
LIMIT 5;
