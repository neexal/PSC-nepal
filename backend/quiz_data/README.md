# Quiz Data Files

This directory contains JSON files for importing quizzes into the system.

## 📁 Files

- **sample_quiz_template.json** - Template for creating new quizzes
- **nepali_grammar_quiz.json** - Example Nepali language quiz

## 🚀 Quick Usage

### Import a single quiz:
```bash
cd backend
python manage.py import_quiz quiz_data/sample_quiz_template.json
```

### Import all quizzes in this directory:
```bash
python manage.py import_quiz quiz_data/*.json
```

## 📝 Creating New Quizzes

1. Copy `sample_quiz_template.json`
2. Edit the fields (title, topic, category, questions)
3. Save with a descriptive name (e.g., `english_grammar_basic.json`)
4. Import using the command above

## 📖 Full Documentation

See [QUIZ_UPLOAD_GUIDE.md](../QUIZ_UPLOAD_GUIDE.md) for complete documentation.

## ✅ JSON Structure

```json
{
  "title": "Quiz Title",
  "topic": "Brief description",
  "category": "GK",  // GK, Nepali, English, or IT
  "subject": "General Knowledge",
  "duration": 20,
  "questions": [
    {
      "question_text": "Your question?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_option": 0,  // Index of correct answer (0-3)
      "explanation": "Why this is correct",
      "difficulty": "medium"  // easy, medium, or hard
    }
  ]
}
```

## 💡 Tips

- Start with the template
- Keep topics concise
- Add explanations for better learning
- Validate JSON before importing (use jsonlint.com)
- Test with a small quiz first

---

**Happy quiz creating!** 📚
