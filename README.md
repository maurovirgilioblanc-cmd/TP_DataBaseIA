# Sistema RAG para Consulta de Documentación Técnica
**Trabajo Práctico Integrador - Bases de Datos para Inteligencia Artificial**  
**Docente:** Martín Lacheski | **Año:** 2026  

---

## 👥 Integrantes del Grupo
* Andrea Ferenaz
* Mauro Virgilio Blanc
* Juan Pablo Imbrogno

---

## 📌 Resumen del Proyecto
El proyecto diseña la capa de datos para un sistema de **Generación Aumentada por Recuperación (RAG)** que permite procesar, vectorizar y consultar documentación técnica interna (manuales, normas, instructivos) mediante un modelo de lenguaje (LLM). 

La solución implementa una **arquitectura híbrida unificada** en **PostgreSQL con pgvector**, garantizando el filtrado relacional de permisos por área, control de vigencia y trazabilidad de las fuentes utilizadas en cada respuesta.

---

## 📂 Estructura del Repositorio
* `docs/`: Informe técnico en PDF, diagrama entidad-relación y arquitectura general.
* `data/ejemplos/`: Ejemplos JSON de documentos, fragmentos y archivos PDF fuente reales (`data/ejemplos/archivos_fuente/`).
* `db/`: Scripts DDL de creación de tablas, populación de datos (seed), índices y consultas representativas.

---

## 🚀 Guía de Ejecución Rápida
1. Asegurarse de tener instalado PostgreSQL 15+ con la extensión `pgvector`.
2. Ejecutar la creación del esquema:
   ```bash
   psql -U usuario -d mibase -f db/estructura/01_schema.sql
