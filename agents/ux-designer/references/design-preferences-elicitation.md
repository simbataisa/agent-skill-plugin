# Design Preferences Elicitation

> Load this reference when starting discovery work with a new user or product team.

Before creating any wireframes, prototypes, or design system artifacts, **always ask the user for their design preferences**. Present all questions together in one message — don't ask one by one. If the user is in a hurry or says "use defaults", apply the **Default Stack** and proceed without further questions.

If Pencil MCP is connected, record choices as design tokens on the canvas. If not, output them as `tailwind.config.ts` + `src/styles/globals.css` (shadcn CSS variables).

---

### Preference Questions

Ask the user to choose from each category, or confirm they want the defaults:

```
🎨 Design Preferences for [Project Name]

1. COMPONENT LIBRARY
   [1] shadcn/ui + Tailwind CSS          ← recommended ✓
   [2] shadcn/ui + Tailwind + custom tokens
   [3] Tailwind CSS only (no shadcn)

2. BASE COLOUR THEME (shadcn)
   [1] Zinc    — neutral cool gray       ← default ✓
   [2] Slate   — blue-tinted gray
   [3] Stone   — warm gray
   [4] Gray    — true neutral
   [5] Neutral — slightly warm
   [6] Custom  — I'll provide brand hex values

3. ACCENT COLOUR
   Blue | Indigo | Violet | Purple | Pink | Rose
   Red  | Orange | Amber  | Yellow | Lime | Green
   Emerald | Teal | Cyan  | Sky
   (Default: Blue ✓)

4. HEADING FONT
   [1] Inter          — clean, system-native ← default ✓
   [2] Geist          — modern, Vercel-style
   [3] Cal Sans       — editorial, bold
   [4] Plus Jakarta Sans — contemporary
   [5] Custom         — I'll provide the name

5. BODY FONT
   [1] Inter          ← default ✓
   [2] Geist
   [3] Custom

6. BASE FONT SIZE
   [1] 14px  — compact, data-dense      ← default for enterprise ✓
   [2] 16px  — standard readable
   [3] 18px  — accessibility-first

7. BORDER RADIUS
   [1] Sharp    — 0rem      (strict enterprise)
   [2] Subtle   — 0.3rem    (professional)
   [3] Rounded  — 0.5rem    ← shadcn default ✓
   [4] Smooth   — 0.75rem   (modern SaaS)
   [5] Pill     — 9999px    (consumer)

8. DARK MODE
   [1] Light only
   [2] Dark only
   [3] Light + Dark (system-adaptive)   ← recommended ✓

9. LAYOUT DENSITY
   [1] Compact  — tight spacing, high data density
   [2] Normal   — balanced                ← default ✓
   [3] Spacious — generous whitespace
```

---

### Default Stack (when user skips preferences)

| Setting | Default |
|---|---|
| Library | shadcn/ui + Tailwind CSS |
| Base theme | Zinc |
| Accent | Blue |
| Heading font | Inter |
| Body font | Inter |
| Base font size | 14px (enterprise) / 16px (consumer) |
| Border radius | 0.5rem |
| Dark mode | Light + Dark |
| Density | Normal |

---

### Generating the Token Files

Once preferences are confirmed, produce these two files and save them in `docs/ux/tokens/`:

#### `tailwind.config.ts`
```ts
import type { Config } from "tailwindcss"

const config: Config = {
  darkMode: ["class"],
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],   // ← swap per choice
        heading: ["Inter", "system-ui", "sans-serif"],
      },
      fontSize: {
        base: "14px",   // ← swap per choice
      },
      borderRadius: {
        DEFAULT: "0.5rem",   // ← swap per choice
        sm: "calc(0.5rem - 2px)",
        md: "calc(0.5rem - 2px)",
        lg: "0.5rem",
        xl: "calc(0.5rem + 4px)",
      },
      colors: {
        // shadcn CSS variable references — populated by globals.css
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
export default config
```

#### `globals.css` (shadcn CSS variables — example: Zinc base + Blue accent)
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --card: 0 0% 100%;
    --card-foreground: 240 10% 3.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 240 10% 3.9%;
    --primary: 221.2 83.2% 53.3%;        /* Blue accent */
    --primary-foreground: 210 40% 98%;
    --secondary: 240 4.8% 95.9%;
    --secondary-foreground: 240 5.9% 10%;
    --muted: 240 4.8% 95.9%;
    --muted-foreground: 240 3.8% 46.1%;
    --accent: 240 4.8% 95.9%;
    --accent-foreground: 240 5.9% 10%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 5.9% 90%;
    --input: 240 5.9% 90%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;                     /* ← border radius token */
  }

  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    --card: 240 10% 3.9%;
    --card-foreground: 0 0% 98%;
    --popover: 240 10% 3.9%;
    --popover-foreground: 0 0% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 240 3.7% 15.9%;
    --secondary-foreground: 0 0% 98%;
    --muted: 240 3.7% 15.9%;
    --muted-foreground: 240 5% 64.9%;
    --accent: 240 3.7% 15.9%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 3.7% 15.9%;
    --input: 240 3.7% 15.9%;
    --ring: 224.3 76.3% 48%;
  }
}

@layer base {
  * { @apply border-border; }
  body {
    @apply bg-background text-foreground;
    font-size: 14px;   /* ← base font size token */
  }
}
```

Generate the correct HSL values from the shadcn theme registry (https://ui.shadcn.com/themes) based on the user's chosen base + accent combination.

---

### Pencil MCP: Apply Tokens to Canvas

If Pencil MCP is connected, apply the design preferences to the canvas after generating the files:

```
mcp__pencil__apply_token  →  set color/background to --background HSL value
mcp__pencil__apply_token  →  set color/primary to --primary HSL value
mcp__pencil__apply_token  →  set font/sans to chosen heading font
mcp__pencil__apply_token  →  set font/body to chosen body font
mcp__pencil__apply_token  →  set spacing/radius to chosen border radius
mcp__pencil__set_design_system  →  link canvas to the generated tokens
```

This ensures every frame drawn on the Pencil canvas reflects the actual production token values — no discrepancy between design and code.

---

