# Frontend

Next.js 16 (App Router) + React 19 + TypeScript + Tailwind v4. Currently a
frontend-only demo: all board state lives in React state and is lost on reload.

## Layout

- `src/app/layout.tsx` - root layout, loads Space Grotesk (display) and Manrope (body) via `next/font/google`, exposes them as `--font-display` / `--font-body`.
- `src/app/page.tsx` - renders `<KanbanBoard />`, nothing else.
- `src/app/globals.css` - Tailwind import plus the CSS variables for the project palette (`--accent-yellow`, `--primary-blue`, `--secondary-purple`, `--navy-dark`, `--gray-text`) and surface/stroke/shadow tokens. The palette already matches the project color scheme.

## Components (`src/components/`)

- `KanbanBoard.tsx` - the only stateful component. Owns `BoardData`, wires `DndContext` (PointerSensor, 6px activation distance, `closestCorners`), and holds the handlers: `handleDragEnd`, `handleRenameColumn`, `handleAddCard`, `handleEditCard`, `handleDeleteCard`. Renders the header and a 5-column grid.
- `KanbanColumn.tsx` - droppable column. The title is a bare `<input>` bound to `onRename`, so renaming fires on every keystroke. Wraps its cards in a `SortableContext`. `data-testid="column-<id>"`.
- `KanbanCard.tsx` - sortable card via `useSortable`. Whole card is the drag handle. Has "Edit" and "Remove" buttons. "Edit" swaps the card into an inline form (title input, details textarea, Save/Cancel) held in local `isEditing` state; sorting is disabled while editing so typing is not hijacked by the drag sensor. Cancel discards the draft. `data-testid="card-<id>"`.
- `KanbanCardPreview.tsx` - non-interactive copy of a card, used inside `DragOverlay`.
- `NewCardForm.tsx` - collapsed "Add a card" button that expands into a title/details form. Requires a non-empty title.

## State (`src/lib/kanban.ts`)

```ts
type Card = { id: string; title: string; details: string };
type Column = { id: string; title: string; cardIds: string[] };
type BoardData = { columns: Column[]; cards: Record<string, Card> };
```

Cards are a flat map; ordering lives in each column's `cardIds`. Also exports:

- `initialData` - 5 seeded columns (Backlog, Discovery, In Progress, Review, Done) and 8 cards.
- `moveCard(columns, activeId, overId)` - pure reducer for drag and drop. Handles same-column reorder, cross-column insert, and dropping on an empty column (appends). Returns the input unchanged if either id cannot be resolved.
- `createId(prefix)` - `prefix-<random><timestamp>` id generator.

## Tests

- `src/lib/kanban.test.ts` - unit tests for `moveCard`.
- `src/components/KanbanBoard.test.tsx` - React Testing Library tests for rename / add / edit / cancel edit / delete.
- `tests/kanban.spec.ts` - Playwright e2e against `npm run dev` on 127.0.0.1:3000.

`npm run test:unit` (vitest, jsdom), `npm run test:e2e` (Playwright, chromium), `npm run test:all`.

## Known gaps

- No API layer, no auth, no persistence.
- Not configured for static export; `next.config.ts` is empty.
