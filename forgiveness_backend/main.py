from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import os
import random

app = FastAPI(title="PeacePlus AI API", version="2.0.0")

# Enable CORS for Flutter app & web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ConflictRequest(BaseModel):
    conflict: str
    religion: Optional[str] = "General"
    perspective: Optional[str] = "Aggrieved"  # Aggrieved, Offender, Mediator

@app.get("/")
@app.get("/health")
def health_check():
    return {"status": "online", "service": "PeacePlus AI API", "version": "2.0.0"}

@app.post("/forgiveness")
async def get_forgiveness_advice(request: ConflictRequest):
    conflict = request.conflict.strip()
    religion = request.religion or "General"
    perspective = request.perspective or "Aggrieved"

    if not conflict:
        raise HTTPException(status_code=400, detail="Conflict description cannot be empty.")

    api_key = os.getenv("OPENAI_API_KEY")

    if api_key:
        try:
            import openai
            openai.api_key = api_key
            prompt = (
                f"You are a compassionate PeacePlus AI Counselor.\n"
                f"Situation: '{conflict}'\n"
                f"Perspective: {perspective}\n"
                f"Tradition/Framework: {religion}\n\n"
                f"Provide advice structured in JSON format with fields: 'reflection', 'action_steps' (list), 'scripture', 'apology_draft'."
            )
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=400,
                temperature=0.7,
            )
            raw_text = response['choices'][0]['message']['content']
            return {"advice": raw_text, "source": "OpenAI"}
        except Exception as e:
            print(f"OpenAI API call failed: {e}. Falling back to PeacePlus Rule Engine.")

    # Fallback Intelligent Forgiveness Recommendation Engine
    advice_payload = generate_rule_based_advice(conflict, religion, perspective)
    return advice_payload

def generate_rule_based_advice(conflict: str, religion: str, perspective: str):
    scriptures = {
        "Christianity": [
            "Colossians 3:13 – Bear with each other and forgive one another if any of you has a grievance against someone. Forgive as the Lord forgiven you.",
            "Ephesians 4:32 – Be kind and compassionate to one another, forgiving each other, just as in Christ God forgiven you.",
            "Matthew 6:14 – For if you forgive other people when they sin against you, your heavenly Father will also forgive you."
        ],
        "Islam": [
            "Surah Ash-Shura 42:40 – The reward of an evil deed is its equivalent, but whoever pardons and makes reconciliation will find their reward with Allah.",
            "Surah An-Nur 24:22 – Let them pardon and overlook. Would you not like that Allah should forgive you?",
            "Hadith (Tirmidhi) – The compassionate ones are shown compassion by the Most Compassionate. Be compassionate to those on earth."
        ],
        "Hinduism": [
            "Bhagavad Gita 16.3 – Forgiveness, fortitude, purity, absence of hatred and pride are the qualities of one endowed with divine nature.",
            "Mahabharata 5.33.48 – Forgiveness is the strength of the virtuous; forgiveness is sacrifice; forgiveness is peace of mind.",
            "Subhashita – Forgiveness adorns a hero; it is the ultimate virtue."
        ],
        "Buddhism": [
            "Dhammapada 1.5 – Hatred does not cease by hatred, but only by love; this is the eternal rule.",
            "Buddha – Holding onto anger is like drinking poison and expecting the other person to die.",
            "Santideva – If there is a remedy, why be unhappy? If there is no remedy, what use is being unhappy?"
        ],
        "Judaism": [
            "Proverbs 19:11 – A person's wisdom yields patience; it is to one's glory to overlook an offense.",
            "Leviticus 19:18 – Do not seek revenge or bear a grudge against anyone among your people, but love your neighbor as yourself.",
            "Mishnah Yoma 8:9 – For offenses between human beings, Yom Kippur does not atone until one appeases their neighbor."
        ],
        "Secular": [
            "Marcus Aurelius – The best revenge is to be unlike him who performed the injury.",
            "Desmond Tutu – Forgiveness is not forgetting; it is taking the poison out of the wound.",
            "Carl Jung – I am not what happened to me, I am what I choose to become."
        ],
        "General": [
            "Patience and open conversation build bridges over deep misunderstandings.",
            "Forgiveness does not mean excusing the behavior; it means freeing yourself from bitterness.",
            "True strength lies in extending grace even when it feels difficult."
        ]
    }

    selected_scripture = random.choice(scriptures.get(religion, scriptures["General"]))

    if perspective == "Offender":
        reflection = f"Acknowledge the weight of your actions in the situation regarding '{conflict}'. True repentance requires genuine empathy for the hurt caused."
        action_steps = [
            "Own your mistake clearly without making excuses or blaming external circumstances.",
            "Express sincere regret directly and ask how you can make amends.",
            "Give the other person space and time to process their emotions without rushing reconciliation."
        ]
        apology = f"I am deeply sorry for my actions regarding {conflict}. I recognize the hurt I caused, and I truly value our relationship. Please let me know how I can make things right."
    elif perspective == "Mediator":
        reflection = f"As a neutral mediator in '{conflict}', your goal is to foster mutual listening, validation, and emotional safety."
        action_steps = [
            "Create a quiet, neutral environment for both parties to share their perspective.",
            "Encourage 'I' statements rather than accusatory language.",
            "Highlight shared values and past positive memories to rebuild connection."
        ]
        apology = f"Let's focus on mutual understanding regarding {conflict}. Both perspectives matter, and finding a peaceful resolution is our shared priority."
    else: # Aggrieved
        reflection = f"Experiencing conflict like '{conflict}' can cause legitimate pain. Forgiveness is a personal journey of releasing resentment for your own peace."
        action_steps = [
            "Acknowledge your hurt feelings without letting them define your actions.",
            "Set clear, respectful boundaries to protect your emotional well-being.",
            "Choose to release the desire to punish the other person, opening room for healing."
        ]
        apology = f"I felt deeply hurt regarding {conflict}, but I care about our peace and connection. I am open to discussing this calmly when you are ready."

    return {
        "status": "success",
        "conflict": conflict,
        "religion": religion,
        "perspective": perspective,
        "reflection": reflection,
        "action_steps": action_steps,
        "scripture": selected_scripture,
        "apology_draft": apology,
        "source": "PeacePlusEngine"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
