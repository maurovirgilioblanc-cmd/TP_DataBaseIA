import psycopg2

DB_CONFIG = {
    "dbname": "rag_docs_db",
    "user": "postgres",
    "password": "Charly432",
    "host": "localhost",
    "port": "5432"
}

def consultar_base_conocimiento(pregunta_texto, usuario_id=1):
    print(f"\n🔍 Buscando respuesta para: '{pregunta_texto}'...")
    
    # Vector dummy de 1536 dimensiones de prueba
    vector_pregunta = [0.01] * 1536  
    vector_str = str(vector_pregunta)

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    # 1. Búsqueda vectorial de fragmentos
    query_busqueda = """
        SELECT 
            f.fragmento_id,
            d.titulo,
            f.contenido_texto,
            f.metadatos->>'pagina_pdf' AS pagina,
            1 - (f.embedding <=> %s::vector) AS similitud
        FROM fragmentos f
        JOIN versiones_documento v ON f.version_id = v.version_id
        JOIN documentos d ON v.documento_id = d.documento_id
        WHERE v.es_activa = TRUE AND d.estado = 'vigente'
        ORDER BY f.embedding <=> %s::vector
        LIMIT 3;
    """
    
    cur.execute(query_busqueda, (vector_str, vector_str))
    resultados = cur.fetchall()

    if not resultados:
        print("⚠️ No se encontraron fragmentos relevantes.")
        cur.close()
        conn.close()
        return

    # 2. Generación/Simulación de la respuesta RAG
    primer_fragmento = resultados[0][2][:150]
    respuesta_ia = f"Basado en la documentación encontrada: {primer_fragmento}..."

    # 3. GUARDAR EN HISTORIAL (Tabla consultas_rag)
    query_insert_consulta = """
        INSERT INTO consultas_rag (usuario_id, pregunta_texto, respuesta_ia, fecha_hora)
        VALUES (%s, %s, %s, NOW())
        RETURNING consulta_id;
    """
    cur.execute(query_insert_consulta, (usuario_id, pregunta_texto, respuesta_ia))
    consulta_id = cur.fetchone()[0]

    # 4. GUARDAR FUENTES Y SCORES (Tabla fuentes_consulta)
    query_insert_fuente = """
        INSERT INTO fuentes_consulta (consulta_id, fragmento_id, score_similitud)
        VALUES (%s, %s, %s);
    """
    
    print("\n📄 Fragmentos más relevantes encontrados:")
    for idx, row in enumerate(resultados, 1):
        frag_id, titulo, texto, pagina, score = row
        score_val = float(score) if score is not None else 0.0
        
        # Insertar la relación en la tabla de trazabilidad
        cur.execute(query_insert_fuente, (consulta_id, frag_id, score_val))

        # Mostrar por pantalla
        pagina_formateada = pagina if pagina is not None else "-"
        print(f"\n--- Resultado #{idx} (Similitud: {round(score_val, 4)}) ---")
        print(f"📌 Documento: {titulo} (Pág. {pagina_formateada})")
        print(f"💬 Texto: {texto[:200]}...")

    # Confirmar cambios en la BD
    conn.commit()
    print(f"\n✅ Consulta registrada en el historial de auditoría con ID #{consulta_id}.")

    cur.close()
    conn.close()

if __name__ == "__main__":
    pregunta = input("Escribí tu pregunta para la base de conocimiento: ")
    consultar_base_conocimiento(pregunta)
