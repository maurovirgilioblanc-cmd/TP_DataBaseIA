# Sistema RAG para Consulta de Documentación Técnica

**Trabajo Práctico Integrador - Bases de Datos para Inteligencia Artificial**  
**Docente:** Martín Lacheski  
**Año:** 2026  

---

## 👥 Integrantes del Grupo
* Andrea Ferenaz
* Mauro Virgilio Blanc
* Juan Pablo Imbrogno

---

## 📌 Resumen del Proyecto
Este proyecto consiste en el diseño e implementación de la capa de datos para un sistema de **Generación Aumentada por Recuperación (RAG - *Retrieval-Augmented Generation*)**. La solución permite ingestar, organizar, fragmentar (*chunking*) y vectorizar documentación técnica interna (manuales de procedimiento, normas de seguridad e instructivos operativos) para ser consultada mediante Inteligencia Artificial (LLM) en lenguaje natural.

La arquitectura de datos implementa una **solución híbrida unificada utilizando PostgreSQL y la extensión `pgvector`**, lo que permite combinar la búsqueda vectorial semántica de baja latencia con el control relacional estricto de accesos por área, control de vigencia documental y trazabilidad completa de las fuentes utilizadas en cada respuesta.

---

## 🏗️ Alcance y Decisiones de Diseño Clave
* **Unificación Tecnológica (PostgreSQL + pgvector):** Evita la complejidad operacional de sincronizar dos bases de datos independientes (relacional + vectorial), permitiendo ejecutar la búsqueda por distancia coseno y los filtros relacionales en una sola consulta atómica.
* **Seguridad y Aislamiento por Área:** Implementación de filtrado obligatorio (`WHERE area_id = ...` / Row Level Security) para evitar la filtración de información confidencial entre áreas o roles.
* **Trazabilidad M:N (Auditoría RAG):** Registro explícito de la relación entre cada consulta realizada por el usuario, la respuesta de la IA y los fragmentos (*chunks*) y versiones exactas de los documentos fuente recuperados.
* **Manejo de Metadatos Semiestructurados:** Uso del tipo de dato `JSONB` para indexar metadatos cambiantes de cada fragmento (página de PDF, párrafo, sección) mediante índices GIN.

---

## 📂 Estructura del Repositorio
El repositorio sigue la organización solicitada por la cátedra:

```text
tp_integrador/
├── README.md                          # Presentación general del proyecto
├── docs/                              # Documentación técnica y diagramas
│   ├── informe.pdf                    # Informe técnico completo
│   ├── modelo_conceptual.png          # Diagrama Entidad-Relación (DER)
│   └── arquitectura.png               # Diagrama de arquitectura de datos
├── data/
│   └── ejemplos/                      # Datos estructurados en JSON y archivos fuente
│       ├── documentos.json
│       ├── fragmentos.json
│       ├── consultas.json
│       └── archivos_fuente/           # Documentos PDF reales de prueba
│           ├── MN-TURB-001.pdf
│           ├── NR-SEG-015.pdf
│           └── IT-ELEC-042.pdf
├── db/                                # Implementación relacional y vectorial en SQL
│   ├── estructura/
│   │   └── 01_schema.sql              # Creación de tablas, FKs y extensión pgvector
│   ├── datos/
│   │   └── 02_seed.sql                # Populación de datos de prueba (Seed)
│   ├── indices_vistas/
│   │   └── 03_indices.sql             # Índices vectoriales HNSW, GIN y B-Tree
│   └── consultas/
│       └── 04_consultas.sql           # 5 consultas representativas de evaluación
└── anexos/
    └── material_complementario.md

---

## 🚀 Guía de Ejecución Rápida

### Requisitos Previos
* PostgreSQL v15 o superior instalado.
* Extensión `pgvector` instalada en el motor de base de datos.

### Pasos para Replicar el Entorno

1. **Clonar el repositorio:**
   git clone https://github.com/tu-usuario/tp_integrador.git
   cd tp_integrador

2. **Crear y preparar la base de datos:**
   createdb rag_docs_db

3. **Ejecutar el esquema físico DDL (Fase 1):**
   psql -U postgres -d rag_docs_db -f db/estructura/01_schema.sql

4. **Cargar el lote de datos de prueba (Fase 2):**
   psql -U postgres -d rag_docs_db -f db/datos/02_seed.sql

5. **Crear los índices de optimización vectorial y B-Tree (Fase 3):**
   psql -U postgres -d rag_docs_db -f db/indices_vistas/03_indices.sql

6. **Ejecutar y validar las consultas representativas (Fase 4):**
   psql -U postgres -d rag_docs_db -f db/consultas/04_consultas.sql

---

## 🛠️ Consultas Incluidas en la Evaluación

En el archivo `db/consultas/04_consultas.sql` se incluyen las consultas requeridas que responden a las necesidades clave del negocio:

* **1. Búsqueda Vectorial Híbrida RAG:** Búsqueda por similitud coseno con filtro de seguridad de área y estado de vigencia del documento.
* **2. Auditoría y Trazabilidad:** Consulta del historial de respuestas RAG con las fuentes exactas y scores de similitud utilizados.
* **3. Métricas y Analytics:** Reporte de los documentos más consultados/citados por la Inteligencia Artificial en los últimos 30 días.
* **4. Control de Obsolecencia e Integridad:** Detección de fragmentos activos pertenecientes a versiones archivadas o dadas de baja.
* **5. Optimización e Índices:** Consulta con análisis de plan de ejecución (`EXPLAIN ANALYZE`) demostrando el uso de los índices HNSW y B-Tree.
