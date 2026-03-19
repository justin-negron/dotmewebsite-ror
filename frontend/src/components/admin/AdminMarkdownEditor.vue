<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, computed } from 'vue'
import { EditorView, keymap, placeholder as cmPlaceholder, ViewUpdate } from '@codemirror/view'
import { EditorState, Compartment, EditorSelection } from '@codemirror/state'
import { markdown, markdownLanguage } from '@codemirror/lang-markdown'
import { languages } from '@codemirror/language-data'
import { defaultKeymap, history, historyKeymap, indentWithTab } from '@codemirror/commands'
import { syntaxHighlighting, HighlightStyle } from '@codemirror/language'
import { tags } from '@lezer/highlight'
import { useTheme } from '@/composables/useTheme'
import { useAppearance } from '@/composables/useAppearance'
import { marked } from 'marked'
import DOMPurify from 'dompurify'

const props = withDefaults(
  defineProps<{
    modelValue: string
    placeholder?: string
    minHeight?: string
    onImageUpload?: (file: File) => Promise<string>
  }>(),
  {
    placeholder: 'Write your post content...',
    minHeight: '400px',
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const { theme: appTheme } = useTheme()
const { skin } = useAppearance()

const editorContainer = ref<HTMLElement | null>(null)
const viewMode = ref<'split' | 'editor' | 'preview'>('split')
let view: EditorView | null = null
let isUpdatingFromProp = false

const themeCompartment = new Compartment()
const highlightCompartment = new Compartment()

const renderedPreview = computed(() => {
  if (!props.modelValue) return ''
  return DOMPurify.sanitize(marked.parse(props.modelValue) as string)
})

/* ======================================================================
   Theme building
   ====================================================================== */
function isDark() {
  return appTheme.value === 'dark'
}

function buildTheme() {
  const dark = isDark()
  return EditorView.theme(
    {
      '&': {
        fontFamily: "'JetBrains Mono', monospace",
        fontSize: '0.85rem',
        backgroundColor: dark ? 'rgba(255,255,255,0.02)' : '#fafaf9',
      },
      '.cm-content': {
        lineHeight: '1.7',
        padding: '0.75rem 0',
        caretColor: dark ? 'var(--skin-400)' : 'var(--skin-600)',
      },
      '&.cm-focused .cm-cursor': {
        borderLeftColor: dark ? 'var(--skin-400)' : 'var(--skin-600)',
      },
      '&.cm-focused .cm-selectionBackground, .cm-selectionBackground': {
        backgroundColor: dark
          ? 'rgba(var(--skin-light-rgb), 0.15)'
          : 'rgba(var(--skin-rgb), 0.12)',
      },
      '.cm-activeLine': {
        backgroundColor: dark
          ? 'rgba(var(--skin-light-rgb), 0.04)'
          : 'rgba(var(--skin-rgb), 0.03)',
      },
      '.cm-gutters': {
        display: 'none',
      },
      '&.cm-focused': {
        outline: 'none',
      },
      '.cm-scroller': {
        overflow: 'auto',
      },
      '.cm-placeholder': {
        color: dark ? '#57534e' : '#a8a29e',
        fontStyle: 'italic',
      },
    },
    { dark },
  )
}

function buildHighlightStyle() {
  const dark = isDark()
  return HighlightStyle.define([
    { tag: tags.heading1, fontWeight: '700', fontSize: '1.3em' },
    { tag: tags.heading2, fontWeight: '700', fontSize: '1.15em' },
    { tag: tags.heading3, fontWeight: '600', fontSize: '1.05em' },
    { tag: tags.strong, fontWeight: '700' },
    { tag: tags.emphasis, fontStyle: 'italic' },
    {
      tag: tags.link,
      color: dark ? 'var(--skin-400)' : 'var(--skin-600)',
      textDecoration: 'underline',
    },
    {
      tag: tags.url,
      color: dark ? 'var(--skin-400)' : 'var(--skin-600)',
    },
    {
      tag: [tags.processingInstruction, tags.monospace],
      fontFamily: "'JetBrains Mono', monospace",
      color: dark ? 'var(--skin-400)' : 'var(--skin-700)',
      backgroundColor: dark ? 'rgba(var(--skin-light-rgb), 0.08)' : 'rgba(var(--skin-rgb), 0.06)',
      borderRadius: '3px',
    },
    {
      tag: tags.quote,
      fontStyle: 'italic',
      color: dark ? '#a8a29e' : '#78716c',
    },
    {
      tag: tags.meta,
      color: dark ? '#78716c' : '#a8a29e',
    },
  ])
}

/* ======================================================================
   CodeMirror initialization
   ====================================================================== */
function createEditor() {
  if (!editorContainer.value) return

  const state = EditorState.create({
    doc: props.modelValue,
    extensions: [
      markdown({ base: markdownLanguage, codeLanguages: languages }),
      history(),
      keymap.of([indentWithTab, ...defaultKeymap, ...historyKeymap]),
      EditorView.lineWrapping,
      cmPlaceholder(props.placeholder),
      themeCompartment.of(buildTheme()),
      highlightCompartment.of(syntaxHighlighting(buildHighlightStyle())),
      EditorView.updateListener.of((update: ViewUpdate) => {
        if (update.docChanged && !isUpdatingFromProp) {
          emit('update:modelValue', update.state.doc.toString())
        }
      }),
      EditorView.domEventHandlers({
        drop: handleDrop,
        paste: handlePaste,
      }),
    ],
  })

  view = new EditorView({
    state,
    parent: editorContainer.value,
  })
}

/* ======================================================================
   Two-way binding
   ====================================================================== */
watch(
  () => props.modelValue,
  (newVal) => {
    if (!view) return
    const current = view.state.doc.toString()
    if (newVal !== current) {
      isUpdatingFromProp = true
      view.dispatch({
        changes: { from: 0, to: current.length, insert: newVal },
      })
      isUpdatingFromProp = false
    }
  },
)

/* ======================================================================
   Skin/theme reactivity
   ====================================================================== */
watch([() => appTheme.value, () => skin.value], () => {
  if (!view) return
  view.dispatch({
    effects: [
      themeCompartment.reconfigure(buildTheme()),
      highlightCompartment.reconfigure(syntaxHighlighting(buildHighlightStyle())),
    ],
  })
})

/* ======================================================================
   Toolbar actions
   ====================================================================== */
function wrapSelection(before: string, after: string, placeholder: string) {
  if (!view) return
  const { from, to } = view.state.selection.main
  const selected = view.state.sliceDoc(from, to)
  const text = selected || placeholder
  const insert = `${before}${text}${after}`

  view.dispatch({
    changes: { from, to, insert },
    selection: selected
      ? EditorSelection.cursor(from + insert.length)
      : EditorSelection.range(from + before.length, from + before.length + text.length),
  })
  view.focus()
}

function prefixLines(prefix: string) {
  if (!view) return
  const { from, to } = view.state.selection.main
  const doc = view.state.doc
  const startLine = doc.lineAt(from)
  const endLine = doc.lineAt(to)

  const changes: { from: number; to: number; insert: string }[] = []
  for (let i = startLine.number; i <= endLine.number; i++) {
    const line = doc.line(i)
    if (line.text.startsWith(prefix)) {
      changes.push({ from: line.from, to: line.from + prefix.length, insert: '' })
    } else {
      changes.push({ from: line.from, to: line.from, insert: prefix })
    }
  }

  view.dispatch({ changes })
  view.focus()
}

function setHeading(level: number) {
  if (!view) return
  const prefix = `${'#'.repeat(level)} `
  const { from } = view.state.selection.main
  const line = view.state.doc.lineAt(from)

  // Remove existing heading prefix
  const match = line.text.match(/^#{1,6}\s/)
  const removeLen = match ? match[0].length : 0

  view.dispatch({
    changes: { from: line.from, to: line.from + removeLen, insert: prefix },
  })
  view.focus()
}

function insertAtCursor(text: string) {
  if (!view) return
  const { from } = view.state.selection.main
  view.dispatch({
    changes: { from, insert: text },
    selection: EditorSelection.cursor(from + text.length),
  })
  view.focus()
}

function insertCodeBlock() {
  if (!view) return
  const { from, to } = view.state.selection.main
  const selected = view.state.sliceDoc(from, to)
  const insert = selected ? `\`\`\`\n${selected}\n\`\`\`` : '```\n\n```'
  const cursorPos = selected ? from + insert.length : from + 4

  view.dispatch({
    changes: { from, to, insert },
    selection: EditorSelection.cursor(cursorPos),
  })
  view.focus()
}

function insertLink() {
  if (!view) return
  const { from, to } = view.state.selection.main
  const selected = view.state.sliceDoc(from, to)

  if (selected) {
    const insert = `[${selected}](url)`
    view.dispatch({
      changes: { from, to, insert },
      selection: EditorSelection.range(from + selected.length + 3, from + selected.length + 6),
    })
  } else {
    const insert = '[link text](url)'
    view.dispatch({
      changes: { from, insert },
      selection: EditorSelection.range(from + 1, from + 10),
    })
  }
  view.focus()
}

function triggerImageUpload() {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/jpeg,image/png,image/gif,image/webp,image/svg+xml'
  input.onchange = () => {
    const file = input.files?.[0]
    if (file) uploadAndInsertImage(file)
  }
  input.click()
}

async function uploadAndInsertImage(file: File) {
  if (!view || !props.onImageUpload) return

  const { from } = view.state.selection.main
  const placeholder = '![Uploading...]()'
  view.dispatch({
    changes: { from, insert: placeholder },
  })

  try {
    const url = await props.onImageUpload(file)
    // Find and replace placeholder
    const doc = view.state.doc.toString()
    const idx = doc.indexOf(placeholder)
    if (idx !== -1) {
      view.dispatch({
        changes: { from: idx, to: idx + placeholder.length, insert: `![image](${url})\n` },
      })
    }
  } catch {
    // Remove placeholder on failure
    const doc = view.state.doc.toString()
    const idx = doc.indexOf(placeholder)
    if (idx !== -1) {
      view.dispatch({
        changes: { from: idx, to: idx + placeholder.length, insert: '' },
      })
    }
  }
}

/* ======================================================================
   Drag-and-drop / Paste
   ====================================================================== */
function handleDrop(event: DragEvent) {
  const files = event.dataTransfer?.files
  if (!files?.length) return false

  const imageFiles = Array.from(files).filter((f) => f.type.startsWith('image/'))
  if (imageFiles.length === 0) return false

  event.preventDefault()
  for (const file of imageFiles) {
    uploadAndInsertImage(file)
  }
  return true
}

function handlePaste(event: ClipboardEvent) {
  const files = event.clipboardData?.files
  if (!files?.length) return false

  const imageFiles = Array.from(files).filter((f) => f.type.startsWith('image/'))
  if (imageFiles.length === 0) return false

  event.preventDefault()
  for (const file of imageFiles) {
    uploadAndInsertImage(file)
  }
  return true
}

/* ======================================================================
   Lifecycle
   ====================================================================== */
onMounted(createEditor)

onUnmounted(() => {
  view?.destroy()
  view = null
})

const toolbarGroups = [
  {
    id: 'format',
    actions: [
      { label: 'B', title: 'Bold', action: () => wrapSelection('**', '**', 'bold') },
      { label: 'I', title: 'Italic', action: () => wrapSelection('*', '*', 'italic'), italic: true },
    ],
  },
  {
    id: 'headings',
    actions: [
      { label: 'H1', title: 'Heading 1', action: () => setHeading(1) },
      { label: 'H2', title: 'Heading 2', action: () => setHeading(2) },
      { label: 'H3', title: 'Heading 3', action: () => setHeading(3) },
    ],
  },
  {
    id: 'lists',
    actions: [
      { label: '&bull;', title: 'Unordered list', action: () => prefixLines('- ') },
      { label: '1.', title: 'Ordered list', action: () => prefixLines('1. ') },
      { label: '>', title: 'Blockquote', action: () => prefixLines('> ') },
    ],
  },
  {
    id: 'insert',
    actions: [
      { label: '&#128279;', title: 'Link', action: insertLink },
      { label: '&#128247;', title: 'Image', action: triggerImageUpload },
      { label: '&lt;/&gt;', title: 'Code block', action: insertCodeBlock },
      { label: '&mdash;', title: 'Horizontal rule', action: () => insertAtCursor('\n---\n') },
    ],
  },
]
</script>

<template>
  <div class="editor-root">
    <!-- Toolbar -->
    <div class="editor-toolbar">
      <div class="toolbar-groups">
        <template v-for="(group, gi) in toolbarGroups" :key="group.id">
          <div v-if="gi > 0" class="toolbar-sep" />
          <button
            v-for="action in group.actions"
            :key="action.label"
            type="button"
            class="toolbar-btn"
            :class="{ 'is-italic': action.italic }"
            :title="action.title"
            @click="action.action()"
            v-html="action.label"
          />
        </template>
      </div>

      <div class="mode-switcher">
        <button
          v-for="mode in (['editor', 'split', 'preview'] as const)"
          :key="mode"
          type="button"
          class="mode-btn"
          :class="{ active: viewMode === mode }"
          @click="viewMode = mode"
        >
          {{ mode }}
        </button>
      </div>
    </div>

    <!-- Editor + Preview layout -->
    <div
      class="editor-layout"
      :class="{
        'show-editor-only': viewMode === 'editor',
        'show-preview-only': viewMode === 'preview',
      }"
    >
      <!-- CodeMirror -->
      <div
        v-show="viewMode !== 'preview'"
        ref="editorContainer"
        class="editor-pane"
        :style="{ minHeight }"
      />

      <!-- Live preview -->
      <div v-show="viewMode !== 'editor'" class="preview-pane" :style="{ minHeight }">
        <div v-if="modelValue" class="post-body" v-html="renderedPreview" />
        <p v-else class="preview-empty">Preview will appear here...</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ===================================================================
   Root
   =================================================================== */
.editor-root {
  border: 1.5px solid #e7e5e4;
  border-radius: 10px;
  overflow: hidden;
  background: #fafaf9;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).editor-root {
  background: rgba(var(--skin-light-rgb), 0.02);
  border-color: rgba(var(--skin-light-rgb), 0.1);
}

/* ===================================================================
   Toolbar
   =================================================================== */
.editor-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  padding: 0.4rem 0.6rem;
  background: #f5f5f4;
  border-bottom: 1px solid #e7e5e4;
  flex-wrap: wrap;
}

:is(.dark *).editor-toolbar {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

.toolbar-groups {
  display: flex;
  align-items: center;
  gap: 2px;
  flex-wrap: wrap;
}

.toolbar-sep {
  width: 1px;
  height: 18px;
  background: #d6d3d1;
  margin: 0 4px;
}

:is(.dark *).toolbar-sep {
  background: rgba(var(--skin-light-rgb), 0.12);
}

.toolbar-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  font-weight: 700;
  min-width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: 5px;
  background: transparent;
  color: #57534e;
  cursor: pointer;
  transition: all 0.15s ease;
  padding: 0 4px;
}

.toolbar-btn:hover {
  background: rgba(var(--skin-rgb), 0.08);
  color: var(--skin-700);
}

:is(.dark *).toolbar-btn {
  color: #a8a29e;
}

:is(.dark *).toolbar-btn:hover {
  background: rgba(var(--skin-light-rgb), 0.1);
  color: var(--skin-400);
}

.toolbar-btn.is-italic {
  font-style: italic;
}

/* ===================================================================
   Mode switcher
   =================================================================== */
.mode-switcher {
  display: flex;
  gap: 2px;
  background: rgba(0, 0, 0, 0.04);
  border-radius: 6px;
  padding: 2px;
}

:is(.dark *).mode-switcher {
  background: rgba(var(--skin-light-rgb), 0.06);
}

.mode-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.65rem;
  font-weight: 600;
  padding: 3px 8px;
  border: none;
  border-radius: 4px;
  background: transparent;
  color: #78716c;
  cursor: pointer;
  transition: all 0.15s ease;
  text-transform: lowercase;
}

.mode-btn.active {
  background: #ffffff;
  color: var(--skin-700);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
}

:is(.dark *).mode-btn {
  color: #78716c;
}

:is(.dark *).mode-btn.active {
  background: rgba(var(--skin-light-rgb), 0.1);
  color: var(--skin-400);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

/* ===================================================================
   Layout
   =================================================================== */
.editor-layout {
  display: grid;
  grid-template-columns: 1fr 1fr;
  min-height: v-bind(minHeight);
}

.editor-layout.show-editor-only {
  grid-template-columns: 1fr;
}

.editor-layout.show-preview-only {
  grid-template-columns: 1fr;
}

@media (max-width: 768px) {
  .editor-layout {
    grid-template-columns: 1fr;
  }
}

/* ===================================================================
   Editor pane
   =================================================================== */
.editor-pane {
  overflow: auto;
}

.editor-pane :deep(.cm-editor) {
  height: 100%;
  min-height: v-bind(minHeight);
}

.editor-pane :deep(.cm-scroller) {
  padding: 0 0.75rem;
}

/* ===================================================================
   Preview pane
   =================================================================== */
.preview-pane {
  overflow-y: auto;
  padding: 0.75rem 1rem;
  border-left: 1px solid #e7e5e4;
}

:is(.dark *).preview-pane {
  border-left-color: rgba(var(--skin-light-rgb), 0.06);
}

.editor-layout.show-preview-only .preview-pane {
  border-left: none;
}

@media (max-width: 768px) {
  .preview-pane {
    border-left: none;
    border-top: 1px solid #e7e5e4;
  }

  :is(.dark *).preview-pane {
    border-top-color: rgba(var(--skin-light-rgb), 0.06);
  }
}

.preview-empty {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  color: #a8a29e;
  font-style: italic;
  padding-top: 0.75rem;
}

:is(.dark *).preview-empty {
  color: #57534e;
}

/* ===================================================================
   Post body (markdown preview) — matches BlogPostView.vue styles
   =================================================================== */
.post-body {
  font-size: 0.95rem;
  line-height: 1.8;
  color: #44403c;
}

:is(.dark *).post-body {
  color: #d6d3d1;
}

.post-body :deep(p) {
  margin-bottom: 1.25em;
}
.post-body :deep(p:last-child) {
  margin-bottom: 0;
}

.post-body :deep(h1) {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 2rem 0 0.75rem;
  color: #1c1917;
}
.post-body :deep(h2) {
  font-size: 1.3rem;
  font-weight: 700;
  margin: 1.75rem 0 0.5rem;
  color: #1c1917;
}
.post-body :deep(h3) {
  font-size: 1.1rem;
  font-weight: 600;
  margin: 1.5rem 0 0.4rem;
  color: #1c1917;
}

:is(.dark *).post-body :deep(h1),
:is(.dark *).post-body :deep(h2),
:is(.dark *).post-body :deep(h3) {
  color: #fafaf9;
}

.post-body :deep(ul),
.post-body :deep(ol) {
  margin: 0.5rem 0 1.25rem 1.5rem;
}
.post-body :deep(li) {
  margin-bottom: 0.3em;
}
.post-body :deep(ul) {
  list-style-type: disc;
}
.post-body :deep(ol) {
  list-style-type: decimal;
}

.post-body :deep(code) {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85em;
  padding: 2px 6px;
  border-radius: 4px;
  background: rgba(var(--skin-rgb), 0.08);
  color: var(--skin-700);
}

:is(.dark *).post-body :deep(code) {
  background: rgba(var(--skin-light-rgb), 0.1);
  color: var(--skin-400);
}

.post-body :deep(pre) {
  background: #f4f3f1;
  border-radius: 8px;
  padding: 0.75rem 1rem;
  overflow-x: auto;
  margin: 1.25rem 0;
}
.post-body :deep(pre code) {
  background: transparent;
  padding: 0;
  font-size: 0.85rem;
  color: #44403c;
}

:is(.dark *).post-body :deep(pre) {
  background: #1c1a18;
}
:is(.dark *).post-body :deep(pre code) {
  color: #d6d3d1;
}

.post-body :deep(blockquote) {
  border-left: 3px solid var(--skin-400);
  padding: 0.25rem 0 0.25rem 1rem;
  margin: 1.25rem 0;
  color: #78716c;
  font-style: italic;
}

:is(.dark *).post-body :deep(blockquote) {
  border-left-color: var(--skin-500);
  color: #a8a29e;
}

.post-body :deep(a) {
  color: var(--skin-600);
  text-decoration: underline;
  text-underline-offset: 3px;
}

:is(.dark *).post-body :deep(a) {
  color: var(--skin-400);
}

.post-body :deep(strong) {
  font-weight: 600;
  color: #1c1917;
}
:is(.dark *).post-body :deep(strong) {
  color: #fafaf9;
}

.post-body :deep(hr) {
  border: none;
  border-top: 1px solid #e7e5e4;
  margin: 1.5rem 0;
}
:is(.dark *).post-body :deep(hr) {
  border-top-color: #292524;
}

.post-body :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 8px;
  margin: 1rem 0;
}
</style>
