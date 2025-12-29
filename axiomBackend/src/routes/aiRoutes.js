import OpenAI from 'openai';
import {auth} from '../middleware/auth.js';
import { Router } from 'express';
const router = Router();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Generate UI from description (Phase 3 - Describe-to-Design)
router.post('/generate-ui', auth, async (req, res) => {
  try {
    const { description } = req.body;

    const prompt = `Generate Flutter widget JSON structure for: "${description}"
    
Return ONLY a JSON object with this structure:
{
  "widgets": [
    {
      "id": "unique_id",
      "type": "Container|Text|Button|Card|Row|Column|etc",
      "properties": {
        "text": "...",
        "color": "#RRGGBB",
        "backgroundColor": "#RRGGBB",
        "padding": {"top": 16, "left": 16, "right": 16, "bottom": 16},
        "fontSize": 16,
        "fontWeight": "normal|bold",
        "alignment": "center|left|right"
      },
      "children": [],
      "position": {"x": 0, "y": 0}
    }
  ]
}`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: 'You are a Flutter UI expert. Generate clean widget structures.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7
    });

    const responseText = completion.choices[0].message.content;
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const widgets = jsonMatch ? JSON.parse(jsonMatch[0]) : { widgets: [] };

    res.json(widgets);
  } catch (error) {
    console.error('AI Error:', error);
    res.status(500).json({ error: 'Failed to generate UI', details: error.message });
  }
});

// Generate Flutter code from widgets
router.post('/generate-flutter-code', auth, async (req, res) => {
  try {
    const { widgets } = req.body;

    const prompt = `Convert this widget structure to clean Flutter code:
${JSON.stringify(widgets, null, 2)}

Generate complete Flutter widget code with proper imports.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: 'You are a Flutter code generator.' },
        { role: 'user', content: prompt }
      ]
    });

    const code = completion.choices[0].message.content;
    res.json({ code });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// AI Design Suggestions (Phase 3)
router.post('/suggest-improvements', auth, async (req, res) => {
  try {
    const { widgets } = req.body;

    const prompt = `Analyze this UI structure and suggest improvements:
${JSON.stringify(widgets, null, 2)}

Provide suggestions for:
1. Better spacing and padding
2. Color contrast improvements
3. Alignment fixes
4. Responsive design

Return JSON: {"suggestions": [{"type": "spacing|color|alignment", "message": "...", "widget_id": "..."}]}`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [{ role: 'user', content: prompt }]
    });

    const responseText = completion.choices[0].message.content;
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const suggestions = jsonMatch ? JSON.parse(jsonMatch[0]) : { suggestions: [] };

    res.json(suggestions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export const aiRoutes = router;