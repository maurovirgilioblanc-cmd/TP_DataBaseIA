import os
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
import psycopg2

# ==============================================================================
# CONFIGURACIÓN DE BASE DE DATOS Y RUTA DE MONITOREO
# ==============================================================================
DB_CONFIG = {
    "dbname": "rag_docs_db",
    "user": "postgres",
    "password": "your_password",  # <-- Modificá por tu contraseña de PostgreSQL
    "host": "localhost",
    "port": "5432"
}

# Ruta donde se depositan los PDFs a monitorear
WATCH_DIR = "data/ejemplos/archivos_fuente/"

# ==============================================================================
# FUNCIÓN PRINCIPAL DE PROCESAMIENTO DE PDF
# ==============================================================================
def procesar_pdf(ruta_pdf):
    nombre_archivo = os.path.basename(ruta_pdf)
    print(f"\n🚀 ¡Nuevo PDF detectado!: {nombre_archivo}")
    
    try:
        # 1. Extracción de texto desde el PDF
        loader = PyPDFLoader(ruta_pdf)
        paginas = loader.load()
        
        # 2. Fragmentación del texto (Chunking: 500 caracteres, overlap 50)
        splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
        chunks = splitter.split_documents(paginas)
        print(f"📖 Texto extraído y dividido en {len(chunks)} fragmentos.")

        # 3. Conexión a la base de datos PostgreSQL
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()

        # A. Insertar el documento general en la tabla 'documentos'
        titulo_doc = os.path.splitext(nombre_archivo)[0]
        cur.execute("""
            INSERT INTO documentos (titulo, estado, nivel_acceso_requerido, area_id, categoria_id)
            VALUES (%s, 'vigente', 'Tecnico_Basico', 1, 1)
            RETURNING documento_id;
        """, (f"Documento Automático: {titulo_doc}",))
        doc_id = cur.fetchone()[0]

        # B. Insertar la versión en la tabla 'versiones_documento'
        cur.execute("""
            INSERT INTO versiones_documento (documento_id, numero_version, url_archivo_origen, es_activa)
            VALUES (%s, '1.0', %s, true)
            RETURNING version_id;
        """, (doc_id, ruta_pdf))
        version_id = cur.fetchone()[0]

        # C. Insertar los fragmentos y sus vectores en la tabla 'fragmentos'
        for idx, chunk in enumerate(chunks):
            pagina = chunk.metadata.get("page", 0) + 1
            
            # Generación de vector dummy de 1536 dimensiones para pgvector
            # (En producción real se reemplaza por llamada a la API de OpenAI/Llama)
            vector_dummy = [0.01] * 1536
            
            cur.execute("""
                INSERT INTO fragmentos (version_id, numero_secuencia, contenido_texto, embedding, metadatos)
                VALUES (%s, %s, %s, %s::vector, %s);
            """, (
                version_id,
                idx + 1,
                chunk.page_content,
                vector_dummy,
                f'{{"pagina_pdf": {pagina}, "origen": "{nombre_archivo}"}}'
            ))

        conn.commit()
        cur.close()
        conn.close()
        print(f"✅ ¡Éxito! '{nombre_archivo}' fue procesado e insertado en PostgreSQL/pgvector.")

    except Exception as e:
        print(f"❌ Error al procesar el archivo '{nombre_archivo}': {e}")

# ==============================================================================
# CLASE DE MONITOREO DE CARPETA (WATCHDOG)
# ==============================================================================
class PDFHandler(FileSystemEventHandler):
    def on_created(self, event):
        # Filtrar únicamente archivos con extensión .pdf
        if not event.is_directory and event.src_path.lower().endswith(".pdf"):
            # Esperar 1 segundo para garantizar que la copia del archivo haya finalizado
            time.sleep(1)
            procesar_pdf(event.src_path)

# ==============================================================================
# PUNTO DE ENTRADA / EJECUCIÓN DEL SERVICIO
# ==============================================================================
if __name__ == "__main__":
    # Asegurar que la carpeta de monitoreo exista
    os.makedirs(WATCH_DIR, exist_ok=True)
    
    print(f"👀 Escuchando la carpeta '{WATCH_DIR}'... (Tirá un PDF ahí para probar)")
    
    event_handler = PDFHandler()
    observer = Observer()
    observer.schedule(event_handler, path=WATCH_DIR, recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\n🛑 Servicio de monitoreo detenido.")
    observer.join()
