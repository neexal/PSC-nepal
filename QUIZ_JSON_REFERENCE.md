# 📋 Quiz JSON Quick Reference Card

**Print this page and keep it handy when creating quizzes!**

---

## ✅ Minimum Required Format

```json
{
  "questions": [
    {
      "question_text": "Your question?",
      "options": ["A", "B", "C", "D"],
      "correct_option": 0
    }
  ]
}
```

---

## 🎯 Full Format (All Options)

```json
{
  "questions": [
    {
      "question_text": "Your question here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_option": 0,
      "explanation": "Why this is correct",
      "difficulty": "medium"
    }
  ]
}
```

---

## 📊 Field Reference

| Field | Required | Type | Values | Example |
|-------|----------|------|--------|---------|
| `question_text` | ✅ | Text | Any | "What is 2+2?" |
| `options` | ✅ | Array | 2-6 items | ["3","4","5"] |
| `correct_option` | ✅ | Number | 0,1,2,3... | 1 |
| `explanation` | ❌ | Text | Any | "Because..." |
| `difficulty` | ❌ | Text | easy/medium/hard | "medium" |

---

## ⚠️ Critical: Index Starts at 0!

```
options: ["A", "B", "C", "D"]
          ↓    ↓    ↓    ↓
index:    0    1    2    3

Use 0 for "A", 1 for "B", 2 for "C", 3 for "D"
```

---

## 💡 Example: 5 Questions

```json
{
  "questions": [
    {
      "question_text": "Capital of Nepal?",
      "options": ["Kathmandu", "Pokhara", "Lalitpur", "Bhaktapur"],
      "correct_option": 0,
      "explanation": "Kathmandu is the capital.",
      "difficulty": "easy"
    },
    {
      "question_text": "Mount Everest in Nepali?",
      "options": ["Gaurishankar", "Sagarmatha", "Himalaya", "Annapurna"],
      "correct_option": 1,
      "explanation": "Sagarmatha is the Nepali name.",
      "difficulty": "easy"
    },
    {
      "question_text": "Year Nepal became republic?",
      "options": ["2006", "2007", "2008", "2009"],
      "correct_option": 2,
      "explanation": "Nepal became a republic in 2008.",
      "difficulty": "medium"
    },
    {
      "question_text": "Number of provinces?",
      "options": ["5", "6", "7", "8"],
      "correct_option": 2,
      "explanation": "Nepal has 7 provinces.",
      "difficulty": "easy"
    },
    {
      "question_text": "First President of Nepal?",
      "options": ["Ram Baran Yadav", "Bidya Devi Bhandari", "K.P. Oli", "Prachanda"],
      "correct_option": 0,
      "explanation": "Ram Baran Yadav was first President.",
      "difficulty": "medium"
    }
  ]
}
```

---

## ✔️ JSON Validation Checklist

Before pasting into admin panel:

- [ ] Wrapped in `{"questions": [...]}`
- [ ] Every question has `question_text`, `options`, `correct_option`
- [ ] Options is an array with at least 2 items
- [ ] `correct_option` is 0-based (0, 1, 2, 3...)
- [ ] All brackets and braces match `{} []`
- [ ] All strings in quotes `"..."`
- [ ] Commas between items (not after last item)
- [ ] No trailing commas before `]` or `}`

---

## 🚫 Common Mistakes

### ❌ Wrong
```json
{
  "questions": [
    {...},
    {...}   // Missing comma!
  ]
}
```

### ✅ Correct
```json
{
  "questions": [
    {...},
    {...}   // Comma added
  ]
}
```

---

### ❌ Wrong
```json
"correct_option": 1  // Selects "B", not "A"!
```

### ✅ Correct
```json
"correct_option": 0  // Selects "A"
```

---

### ❌ Wrong
```json
"options": ["A", "B",]  // Trailing comma!
```

### ✅ Correct
```json
"options": ["A", "B"]  // No trailing comma
```

---

## 🔗 Validate Your JSON

Before pasting, check at: **https://jsonlint.com/**

---

## 📍 Where to Paste

1. Admin panel → Quizzes → Add Quiz
2. Scroll to "📤 Bulk Upload Questions"
3. Paste JSON in the text area
4. Click "Save"

---

## 🎉 That's It!

**Save this reference and create quizzes with confidence!**

---

**For detailed guide:** See `ADMIN_QUIZ_UPLOAD.md`
