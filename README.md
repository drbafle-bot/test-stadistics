# Perfil Profesional · Stadistics

**Una herramienta para instalar en Docker, es un sistema de autoevaluación orientativa para ayudar a cada persona a encontrar el lugar donde mejor encaja dentro de una organización.**

---

## Qué es

Stadistics es una aplicación autoalojada que ofrece a los candidatos y empleados de una empresa un cuestionario de autoevaluación profesional. A partir de sus respuestas, la herramienta genera un perfil orientativo que describe en qué áreas de trabajo —técnica, comercial, de diseño, de atención al público, de planificación, entre otras— la persona tiende a sentirse más cómoda y competente, junto con una lectura de rasgos de comportamiento como la iniciativa, la responsabilidad o el compañerismo.

No es un test de inteligencia ni un instrumento de evaluación clínica. Es, en esencia, un espejo: una forma estructurada de que una persona —y, con su consentimiento, la organización para la que trabaja o aspira a trabajar— entienda mejor hacia dónde se inclinan de forma natural sus capacidades y preferencias.

## Cómo funciona

El cuestionario está compuesto por un extenso banco de afirmaciones que el candidato valora según su grado de acuerdo. Sobre esas respuestas, el sistema calcula:

- **Un perfil por área**, que muestra el grado de afinidad con cada uno de los principales roles funcionales de una empresa de servicios tecnológicos.
- **Un conjunto de rasgos de comportamiento**, presentados como escalas independientes, que matizan el perfil anterior.
- **Un índice de sinceridad y fiabilidad**, calculado mediante mecanismos habituales en la construcción de cuestionarios de autoinforme —ítems de control, reformulaciones de consistencia y detección de patrones de respuesta poco atentos—, que advierte cuándo un resultado concreto merece una lectura más cautelosa.

Toda esta información queda disponible, de forma protegida y exclusivamente para la organización, en un panel interno desde el que puede consultarse, exportarse en un informe y, si así se decide, eliminarse.

## Cómo debe usarse

Aquí conviene ser explícito, porque es la parte que con más facilidad se malinterpreta.

Este test **no debe utilizarse jamás como criterio único, ni siquiera como criterio principal, para decidir si se contrata, promociona o desvincula a una persona.** Es un cuestionario de autoinforme, no un instrumento psicométrico validado clínicamente, y cualquier persona con formación en psicología —o simplemente familiarizada con este tipo de dinámicas— puede superarlo con relativa facilidad sin que el resultado refleje con fidelidad su perfil real. El índice de sinceridad mitiga este riesgo, pero no lo elimina.

Su lugar correcto es el de **un factor más, entre otros, dentro de un proceso de decisión mucho más amplio** que debe incluir siempre entrevista personal, valoración técnica cuando el puesto lo requiera y, sobre todo, la observación directa del desempeño real.

Del mismo modo, el uso de esta herramienta con candidatos y empleados exige el tratamiento cuidadoso de sus datos personales: consentimiento informado antes de iniciar el test, transparencia sobre el plazo de conservación de la información y respeto de los derechos que la normativa de protección de datos reconoce a cada persona.

## Categorías y lógica de cada estadística

### Perfil por área

El test distribuye sus preguntas en ocho áreas funcionales, elegidas por representar los perfiles habituales dentro de una empresa de servicios tecnológicos. Cada área se puntúa de forma independiente, como el porcentaje de acuerdo medio que la persona muestra con las afirmaciones asociadas a ella:

- **Técnico** — diagnóstico y resolución metódica de problemas.
- **Programador/a** — pensamiento lógico, algorítmico y de automatización.
- **Diseñador/a** — sensibilidad estética y cuidado de la experiencia visual.
- **Comercial** — orientación al cierre de acuerdos y a la generación de negocio.
- **Cara al público** — trato directo con clientes, paciencia y cercanía.
- **Marketing** — comunicación, posicionamiento y creación de contenido.
- **Planificador/a** — organización de procesos, tiempos y proyectos.
- **Administrador/a** — gestión documental, de recursos y de tareas administrativas.

El **perfil dominante** es, simplemente, el área con mayor puntuación. El **desarrollo general** es la media de las ocho, y ofrece una lectura de conjunto: cuán decantado o cuán equilibrado es el perfil de la persona entre las distintas áreas.

### Rasgos de comportamiento

A diferencia de las áreas anteriores, que compiten entre sí por el perfil dominante, estos tres rasgos se miden de forma independiente, como escalas propias:

- **Iniciativa** — tendencia a actuar por cuenta propia frente a esperar instrucciones (polo pasivo ↔ polo activo).
- **Responsabilidad** — fiabilidad y grado de compromiso con lo que se asume.
- **Compañerismo** — disposición a colaborar y sostener al resto del equipo.

### Índice de sinceridad y fiabilidad

Esta es, quizá, la estadística más delicada de explicar, porque no mide *qué* responde la persona, sino *cómo* de fiable es esa respuesta. Se calcula partiendo de 100 puntos y restando penalizaciones según cuatro mecanismos habituales en la construcción de cuestionarios de autoinforme:

1. **Ítems de infrecuencia.** Afirmaciones formuladas en términos absolutos y poco plausibles en la experiencia real de casi cualquier persona (por ejemplo, no haber tenido nunca dificultad para tomar una decisión). Mostrar acuerdo alto con varias de ellas es indicio de exageración o de falta de atención al responder.

2. **Escala de deseabilidad social.** Un conjunto de afirmaciones "demasiado buenas para ser ciertas" (no perder nunca la paciencia, no haber mentido jamás), que miden la tendencia a proyectar una imagen idealizada de uno mismo más que a describirse con honestidad.

3. **Pares de consistencia.** Algunas afirmaciones se reformulan más adelante en el cuestionario, con otras palabras. Una diferencia grande entre la respuesta original y su reformulación sugiere una respuesta poco atenta o inconsistente.

4. **Detección de respuesta invariable.** Si la varianza de todas las respuestas de una persona es prácticamente nula —es decir, si ha marcado el mismo valor de forma sistemática—, se interpreta como una señal de que el cuestionario no se ha respondido con verdadera atención.

La suma de estas penalizaciones se resta de 100 y da lugar al índice final, acompañado siempre de una etiqueta cualitativa (fiabilidad alta, moderada o baja) que orienta sobre cuánto peso conviene dar al resto del perfil.

## Filosofía del proyecto

Stadistics nace de una convicción sencilla de su autor, **Javier Ballestero Redondo**: una empresa no gana nada reteniendo a un empleado en un puesto que no le hace feliz, y pierde mucho más de lo que a menudo cree cuando esa infelicidad se traduce, tarde o temprano, en su marcha.

La idea que sostiene esta herramienta no es fichar bien a la primera —algo que, además, ningún test puede garantizar—, sino algo más modesto y, a la vez, más ambicioso: **acompañar el recorrido de cada persona dentro de la organización.** No es infrecuente que alguien empiece en un puesto que no es, todavía, el que mejor le sienta. Lo que propone Stadistics es que ese desajuste inicial no tenga por qué ser definitivo: mediante un uso periódico y respetuoso del test —nunca impuesto, siempre con el consentimiento del empleado—, una empresa puede ir detectando hacia dónde evolucionan los intereses y las fortalezas de sus equipos, y reubicar progresivamente a cada persona en el lugar donde de verdad rinde mejor y se siente más a gusto.

Entendida así, esta herramienta no es un filtro de entrada, sino un instrumento de cuidado a largo plazo. Una empresa que ayuda a sus empleados a encontrar, con el tiempo, el puesto que realmente les corresponde no solo construye equipos más felices: construye también, casi como efecto colateral, una plantilla que permanece, que se compromete y que crece con la organización en lugar de abandonarla.

Ese es, en último término, el propósito de Stadistics: no medir a las personas, sino ayudar a que cada una encuentre —dentro de la empresa, y con el tiempo que haga falta— el lugar que le corresponde.

## Instalación

Preparado y probado específicamente para **Ubuntu 26.04** con Docker ya instalado. No se ha probado en distribuciones distintas de las basadas en Debian/Ubuntu; en otros sistemas (Fedora, Arch, etc.) el script de despliegue podría requerir ajustes.

**Requisitos previos:** Docker instalado y en funcionamiento en el servidor.

1. Copia el script `test_stadistics.sh` al servidor (por ejemplo, con `scp`).
2. Dale permisos de ejecución:

   ```bash
   chmod +x test_stadistics.sh
   ```

3. Ejecútalo:

   ```bash
   ./test_stadistics.sh
   ```

   El script crea la estructura del proyecto en `/opt/test-inteligencias`, construye la imagen Docker y levanta el contenedor.

### Cambiar el puerto

Al principio del script, en la variable `PORT`:

```bash
PORT="9050"
```

Cambia `9050` por el puerto que prefieras antes de ejecutar el script.

### Credenciales del panel de empresa

También al principio del script, en las variables `ADMIN_USER` y `ADMIN_PASSWORD`:

```bash
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"
```

Por defecto ambas están fijadas a `admin`. **Se recomienda encarecidamente cambiarlas** antes de desplegar, ya que este panel da acceso a datos personales de candidatos.

## Cómo se usa

- **Candidato/empleado:** accede a `http://IP-DEL-SERVIDOR:PUERTO`, indica su nombre, acepta el consentimiento de protección de datos y completa el test. Al finalizar solo ve su puntuación total; el resultado completo queda guardado automáticamente.
- **Empresa (panel interno):** accede a `http://IP-DEL-SERVIDOR:PUERTO/tests` e introduce el usuario y contraseña configurados en el script. Desde ahí puede consultar el listado de resultados, ver el detalle de cada candidato, descargar el informe en PDF o eliminar un resultado con el botón de papelera.

---

*Herramienta autoalojada, desarrollada por Javier Ballestero Redondo.*
