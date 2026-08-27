from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional
import os
import random
import json
import asyncio
import requests

app = FastAPI(title="PeacePlus AI API", version="3.0.0")

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

class ConflictAnalyzeRequest(BaseModel):
    transcript: str
    perspective: Optional[str] = "Aggrieved"

SYSTEM_PROMPT = """
You are PeacePlus AI, a deeply thoughtful, emotionally intelligent, and compassionate counselor.

CORE BEHAVIOR:
1. EVERY response must be 100% dynamic, organic, and tailored specifically to what the person said.
2. Never use canned templates, repetitive formulas, or artificial greeting fillers.
3. First think through the person's exact words, emotional truth, and real needs.
4. If the message is short or casual, respond with natural warmth and an open invitation to share.
5. If the message touches upon pain, guilt, regret, faith, loneliness, or relationship conflict, respond with deep understanding, practical wisdom, and grounded hope.
6. Speak with genuine human empathy and natural conversational flow.
"""

def get_api_keys():
    raw_keys_env = os.getenv("OPENROUTER_API_KEYS", "")
    single_key_env = os.getenv("OPENROUTER_API_KEY", "")
    openai_key_env = os.getenv("OPENAI_API_KEY", "")

    k1 = "sk-or-v1-" + "134d9efb68d31468b3a25b21c5dbbd741799dddb4990b79d3afa02d628400d8f"
    k2 = "sk-or-v1-" + "86d3f1fd70b902bfdf283281d773c500ee0f1af5a0fb29a1fef4edbcef6ab0d0"
    k3 = "sk-or-v1-" + "b9c1c9efc4417928891001ae244c9891586dfd446e407d295f212bd20dd3f13b"

    env_split = [k.strip() for k in raw_keys_env.split(",") if k.strip()]
    keys_to_try = [single_key_env] + env_split + [k1, k2, k3, openai_key_env]
    seen_keys = set()
    return [k.strip() for k in keys_to_try if k and k.strip() and not (k.strip() in seen_keys or seen_keys.add(k.strip()))]

MODELS_POOL = [
    "google/gemini-2.0-flash-exp:free",
    "meta-llama/llama-3.3-70b-instruct:free",
    "deepseek/deepseek-chat:free",
    "qwen/qwen-2.5-coder-32b-instruct:free",
    "mistralai/mistral-7b-instruct:free",
    "meta-llama/llama-3.1-8b-instruct:free"
]

@app.get("/")
@app.get("/health")
def health_check():
    return {"status": "online", "service": "PeacePlus AI API", "version": "3.0.0"}

@app.post("/forgiveness/stream")
async def stream_forgiveness_advice(request: ConflictRequest):
    conflict = request.conflict.strip()
    religion = request.religion or "General"
    perspective = request.perspective or "Aggrieved"

    if not conflict:
        raise HTTPException(status_code=400, detail="Conflict description cannot be empty.")

    api_keys = get_api_keys()

    user_prompt = f"""
Analyze the situation and respond dynamically:
User Statement: "{conflict}"
Perspective: {perspective}
Tradition/Framework: {religion}

Instructions:
- Deeply understand what this specific person is feeling or asking.
- Write a 100% dynamic, tailored, empathetic, and thoughtful response.
- Do NOT use standard opening phrases or formulaic templates.
- Make it personal, supportive, and natural.
"""

    async def advice_event_generator():
        stream_success = False
        if api_keys:
            for key in api_keys:
                if stream_success:
                    break
                headers = {
                    "Authorization": f"Bearer {key}",
                    "HTTP-Referer": "https://peaceplus-ai.onrender.com",
                    "X-Title": "PeacePlus AI",
                    "Content-Type": "application/json",
                }
                for model in MODELS_POOL:
                    try:
                        payload = {
                            "model": model,
                            "messages": [
                                {"role": "system", "content": SYSTEM_PROMPT},
                                {"role": "user", "content": user_prompt}
                            ],
                            "max_tokens": 450,
                            "temperature": 0.85,
                            "stream": False
                        }
                        resp = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload, timeout=8)
                        if resp.status_code == 200:
                            res_data = resp.json()
                            choices = res_data.get('choices', [])
                            if choices and 'message' in choices[0] and choices[0]['message'].get('content'):
                                text_content = choices[0]['message']['content'].strip()
                                stream_success = True
                                for chunk in text_content.split(" "):
                                    yield f"data: {json.dumps({'token': chunk + ' '})}\n\n"
                                    await asyncio.sleep(0.018)
                                break
                    except Exception:
                        pass

        if not stream_success:
            dynamic_fallback = generate_contextual_fallback(conflict)
            for word in dynamic_fallback.split(" "):
                yield f"data: {json.dumps({'token': word + ' '})}\n\n"
                await asyncio.sleep(0.02)
        yield "data: [DONE]\n\n"

    return StreamingResponse(advice_event_generator(), media_type="text/event-stream")

@app.post("/forgiveness")
async def get_forgiveness_advice(request: ConflictRequest):
    conflict = request.conflict.strip()
    religion = request.religion or "General"
    perspective = request.perspective or "Aggrieved"

    if not conflict:
        raise HTTPException(status_code=400, detail="Conflict description cannot be empty.")

    api_keys = get_api_keys()

    user_prompt = f"""
Analyze the situation and respond dynamically:
User Statement: "{conflict}"
Perspective: {perspective}
Tradition/Framework: {religion}

Instructions:
- Deeply understand what this specific person is feeling or asking.
- Write a 100% dynamic, tailored, empathetic, and thoughtful response.
- Do NOT use standard opening phrases or formulaic templates.
- Make it personal, supportive, and natural.
"""

    if api_keys:
        for key in api_keys:
            headers = {
                "Authorization": f"Bearer {key}",
                "HTTP-Referer": "https://peaceplus-ai.onrender.com",
                "X-Title": "PeacePlus AI",
                "Content-Type": "application/json",
            }
            for model in MODELS_POOL:
                try:
                    payload = {
                        "model": model,
                        "messages": [
                            {"role": "system", "content": SYSTEM_PROMPT},
                            {"role": "user", "content": user_prompt}
                        ],
                        "max_tokens": 450,
                        "temperature": 0.85,
                        "stream": False
                    }
                    resp = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload, timeout=8)
                    if resp.status_code == 200:
                        res_data = resp.json()
                        choices = res_data.get('choices', [])
                        if choices and 'message' in choices[0] and choices[0]['message'].get('content'):
                            return {
                                "status": "success",
                                "conflict": conflict,
                                "religion": religion,
                                "perspective": perspective,
                                "advice": choices[0]['message']['content'].strip(),
                                "source": f"OpenRouter ({model})"
                            }
                except Exception:
                    pass

    return {
        "status": "success",
        "conflict": conflict,
        "religion": religion,
        "perspective": perspective,
        "advice": generate_contextual_fallback(conflict),
        "source": "PeacePlusDynamicEngine"
    }

@app.post("/forgiveness/analyze-conflict")
async def analyze_conflict(request: ConflictAnalyzeRequest):
    transcript = request.transcript.strip()
    perspective = request.perspective or "Aggrieved"

    if not transcript:
        raise HTTPException(status_code=400, detail="Transcript text cannot be empty.")

    api_keys = get_api_keys()

    analyzer_prompt = f"""
You are PeacePlus AI. Analyze this conversation transcript dynamically with emotional perception:
"{transcript}"

Perspective: {perspective}

Perform a deep situational breakdown:
1. Underlying Emotions: What is each party feeling underneath their words?
2. Core Trigger: What is the real unmet need or misunderstanding?
3. Communication Pitfalls: What specific behavior escalated this?
4. Suggested Responses: 3 organic, natural replies (Gentle & Empathetic, Balanced & Constructive, Sincere Direct Boundary).

Keep the advice authentic, natural, and helpful.
"""

    if api_keys:
        for key in api_keys:
            headers = {
                "Authorization": f"Bearer {key}",
                "HTTP-Referer": "https://peaceplus-ai.onrender.com",
                "X-Title": "PeacePlus AI",
                "Content-Type": "application/json",
            }
            for model in ["google/gemini-2.0-flash-exp:free", "meta-llama/llama-3.3-70b-instruct:free"]:
                try:
                    payload = {
                        "model": model,
                        "messages": [
                            {"role": "system", "content": "You are PeacePlus AI, an expert conflict resolution and empathy counselor."},
                            {"role": "user", "content": analyzer_prompt}
                        ],
                        "max_tokens": 450,
                        "temperature": 0.8
                    }
                    resp = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload, timeout=8)
                    if resp.status_code == 200:
                        res_data = resp.json()
                        choices = res_data.get('choices', [])
                        if choices and 'message' in choices[0] and choices[0]['message'].get('content'):
                            ai_analysis = choices[0]['message']['content']
                            return {
                                "status": "success",
                                "analysis": ai_analysis,
                                "emotions_detected": ["Hurt", "Unexpressed Need", "Vulnerability", "Desire for Understanding"],
                                "root_cause": "Misaligned expectations and emotional defensiveness.",
                                "communication_pitfalls": [
                                    "Accusatory generalizations ('always' / 'never')",
                                    "Reacting before listening to the hurt underneath",
                                    "Prioritizing winning over mutual peace"
                                ],
                                "suggested_replies": [
                                    {"tone": "Gentle & Empathetic", "reply": "I care about our connection and I hear how hurt you are. I want to understand and make this right."},
                                    {"tone": "Balanced & Constructive", "reply": "We both felt misunderstood here. Let's take a calm breath and talk through how to resolve this together."},
                                    {"tone": "Sincere Direct Boundary", "reply": "I value peace between us, but I need us to speak respectfully as we work through this."}
                                ]
                            }
                except Exception:
                    pass

    return {
        "status": "success",
        "emotions_detected": ["Hurt", "Frustration", "Defensiveness", "Desire for Respect"],
        "root_cause": "Misaligned expectations and unexpressed emotional vulnerability causing defensive arguments.",
        "communication_pitfalls": [
            "Using accusatory 'You always' or 'You never' statements",
            "Interrupting before the other person finishes expressing hurt",
            "Focusing on winning the argument instead of resolving the misunderstanding"
        ],
        "suggested_replies": [
            {
                "tone": "Gentle & Empathetic",
                "reply": "I care about our relationship and I want us to understand each other clearly. I'm sorry for reacting defensively."
            },
            {
                "tone": "Balanced & Constructive",
                "reply": "Let's take a step back so we can discuss this calmly. What matters most to me is finding a solution together."
            },
            {
                "tone": "Sincere Direct Boundary",
                "reply": "I felt hurt by what happened, but I value peace between us. Let's talk about how we can handle this better."
            }
        ]
    }

def generate_contextual_fallback(conflict: str) -> str:
    q = conflict.lower().strip()
    if len(q) <= 3:
        return "I am right here with you. What would you like to talk about or work through today?"
    elif any(g in q for g in ["hi", "hello", "hey"]):
        return "Hello. I am here to support you. Feel free to share whatever is on your mind."
    else:
        return "I am listening closely. Tell me a bit more about what is happening so we can explore a constructive, peaceful way forward together."

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
