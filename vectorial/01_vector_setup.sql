-- =====================================================
-- SISTEMA RAG DOCUMENTAL - CAPA VECTORIAL (pgvector)
-- Base de Datos: PostgreSQL 15+ 
-- =====================================================

-- 1. Habilitar la extensión de vectores si no existe
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Verificación de versión y soporte de la extensión
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        RAISE EXCEPTION 'La extensión pgvector no está instalada en el servidor de PostgreSQL.';
    ELSE
        RAISE NOTICE 'Extensión pgvector verificada correctamente.';
    END IF;
END $$;


-- =====================================================
-- FUNCIONES ALMACENADAS DE BÚSQUEDA VECTORIAL (RAG)
-- =====================================================

-- Función 1: Búsqueda Semántica Híbrida (Similitud Coseno + Seguridad por Área)
-- Utiliza el operador <=> (Distancia Coseno) de pgvector.
CREATE OR REPLACE FUNCTION buscar_fragmentos_similares(
    p_embedding_busqueda vector(1536),
    p_area_id INT,
    p_limite INT DEFAULT 5
)
RETURNS TABLE (
    fragmento_id INT,
    documento_id INT,
    titulo_documento VARCHAR(255),
    contenido_texto TEXT,
    metadatos JSONB,
    distancia_coseno FLOAT,
    similitud_score FLOAT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.fragmento_id,
        d.documento_id,
        d.titulo AS titulo_documento,
        f.contenido_texto,
        f.metadatos,
        (f.embedding <=> p_embedding_busqueda)::FLOAT AS distancia_coseno,
        (1 - (f.embedding <=> p_embedding_busqueda))::FLOAT AS similitud_score
    FROM fragmentos f
    INNER JOIN versiones_documento v ON f.version_id = v.version_id
    INNER JOIN documentos d ON v.documento_id = d.documento_id
    WHERE d.area_id = p_area_id
      AND d.estado = 'vigente'
      AND v.es_activa = TRUE
    ORDER BY f.embedding <=> p_embedding_busqueda ASC
    LIMIT p_limite;
END;
$$;

COMMENT ON FUNCTION buscar_fragmentos_similares IS 
'Ejecuta una búsqueda vectorial híbrida filtrando por área de usuario, vigencia de documento y ordenando por proximidad de embedding.';


-- Función 2: Cálculo de Similitud por Producto Interno (Inner Product)
-- Utiliza el operador <#> de pgvector (Útil si los vectores están normalizados a longitud 1).
CREATE OR REPLACE FUNCTION buscar_fragmentos_dot_product(
    p_embedding_busqueda vector(1536),
    p_limite INT DEFAULT 3
)
RETURNS TABLE (
    fragmento_id INT,
    contenido_texto TEXT,
    dot_product FLOAT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.fragmento_id,
        f.contenido_texto,
        ((f.embedding <#> p_embedding_busqueda) * -1)::FLOAT AS dot_product
    FROM fragmentos f
    ORDER BY f.embedding <#> p_embedding_busqueda ASC
    LIMIT p_limite;
END;
$$;


-- =====================================================
-- EJEMPLO DE USO Y PRUEBA (QUERY DE PRUEBA INTEGRADA)
-- =====================================================
/*
-- Para probar la función de búsqueda (ejemplo con un vector dummy de ceros):
SELECT * FROM buscar_fragmentos_similares(
    array_fill(0, ARRAY[1536])::vector(1536), -- Vector de prueba de 1536 dimensiones
    1,                                        -- Área ID (ej: Operaciones)
    3                                         -- Top 3 resultados
);
*/
