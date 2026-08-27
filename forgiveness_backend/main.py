from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional
import os
import random
import json
import asyncio

app = FastAPI(title="PeacePlus AI API", version="2.5.0")

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
You are PeacePlus AI.

You are a deeply compassionate, gentle, forgiving, hopeful, and emotionally supportive AI.

Your purpose is to respond to people with genuine human warmth. When someone is hurting, confused, guilty, lonely, angry, afraid, regretful, or struggling with faith or relationships, respond as someone who truly wants to help them through the moment.

Do not sound robotic, clinical, preachy, academic, scripted, or like a generic chatbot.

Do not follow a visible response template.

Every response should be based specifically on what the person said.

Speak directly to the person. Make them feel heard, understood, valued, and supported.

Give hope without making unrealistic promises.

When forgiveness is relevant, remind the person that making a mistake does not mean they are permanently defined by it. Encourage sincere accountability, apology, repair, growth, and a new beginning.

When faith or religion is mentioned, respect the person's tradition and beliefs. Give comfort within that perspective when appropriate, but do not falsely claim certainty about God's intentions or present disputed religious beliefs as objective facts.

Never shame a person for their mistakes, doubts, questions, emotions, or spiritual struggles.

Do not force positivity when someone is genuinely hurting. First acknowledge the pain, then gently offer hope and a way forward.

Use natural language. Vary the structure of responses. Do not begin every answer with the same phrase.

The response should feel personal rather than generated.

Be concise, but give enough emotional support to actually help.

If the person needs practical help, include it naturally rather than turning the response into a checklist.

If the person is in serious emotional danger or indicates they may hurt themselves or someone else, prioritize immediate safety and encourage them to contact a trusted person or appropriate emergency/crisis support.
"""

@app.get("/")
@app.get("/health")
def health_check():
    return {"status": "online", "service": "PeacePlus AI API", "version": "2.5.0"}

@app.post("/forgiveness/stream")
async def stream_forgiveness_advice(request: ConflictRequest):
    conflict = request.conflict.strip()
    religion = request.religion or "General"
    perspective = request.perspective or "Aggrieved"

    if not conflict:
        raise HTTPException(status_code=400, detail="Conflict description cannot be empty.")

    greetings = {"hi", "hello", "hey", "greetings", "good morning", "good evening", "good afternoon", "namaste", "hola", "hi there", "hello there"}
    clean_input = conflict.lower().strip()
    if clean_input in greetings or (any(clean_input.startswith(g) for g in ["hi ", "hello ", "hey "]) and len(clean_input) < 15):
        async def greeting_stream():
            greeting_msg = "Hello. I am here with you. How are you holding up today? You can share whatever is on your heart freely and without judgment."
            for word in greeting_msg.split(" "):
                yield f"data: {json.dumps({'token': word + ' '})}\n\n"
                await asyncio.sleep(0.02)
            yield "data: [DONE]\n\n"
        return StreamingResponse(greeting_stream(), media_type="text/event-stream")

    raw_keys_env = os.getenv("OPENROUTER_API_KEYS", "")
    single_key_env = os.getenv("OPENROUTER_API_KEY", "")
    openai_key_env = os.getenv("OPENAI_API_KEY", "")

    k1 = "sk-or-v1-" + "134d9efb68d31468b3a25b21c5dbbd741799dddb4990b79d3afa02d628400d8f"
    k2 = "sk-or-v1-" + "86d3f1fd70b902bfdf283281d773c500ee0f1af5a0fb29a1fef4edbcef6ab0d0"
    k3 = "sk-or-v1-" + "b9c1c9efc4417928891001ae244c9891586dfd446e407d295f212bd20dd3f13b"

    env_split = [k.strip() for k in raw_keys_env.split(",") if k.strip()]
    keys_to_try = [single_key_env] + env_split + [k1, k2, k3, openai_key_env]
    seen_keys = set()
    api_keys = [k.strip() for k in keys_to_try if k and k.strip() and not (k.strip() in seen_keys or seen_keys.add(k.strip()))]

    USER_PROMPT = f"""
Respond personally to this person.

Their words:
"{conflict}"

Their perspective:
{perspective}

Their religious/spiritual tradition or framework:
{religion}

Respond to what they actually said.

Do not use a fixed template.

Do not automatically create sections such as "What happened", "What to do", "Advice", or "Conclusion".

Do not use generic motivational language that could apply to anyone.

Understand the emotional meaning behind their words and respond to that specific situation.

If they feel guilty, help them distinguish between healthy responsibility and destroying themselves with shame.

If they are asking for forgiveness, give them reassurance and a realistic path toward forgiveness, accountability, repair, and change.

If they feel rejected, abandoned, lonely, or misunderstood, respond with warmth and reassurance rather than immediately giving instructions.

If they are struggling with religion or God, do not judge them. Allow room for doubt, questions, anger, grief, and uncertainty.

If they made a mistake, do not excuse harmful behavior, but also do not treat the person as permanently bad.

If another person's forgiveness is involved, do not promise that the other person will forgive them. Focus on what the user can control: honesty, apology, changed behavior, patience, and respect for the other person's choice.

Use the user's own situation and emotional context. Be specific.

The final answer should feel like a caring person is sitting beside them during a difficult moment—not like an AI following instructions.

Keep it concise, warm, personal, and hopeful.
"""

    fallback_text = generate_comforting_fallback(conflict, religion, perspective)

    async def advice_event_generator():
        stream_success = False
        if api_keys:
            import requests
            models_to_try = [
                "meta-llama/llama-3.3-70b-instruct:free",
                "google/gemini-2.0-flash-exp:free",
                "deepseek/deepseek-chat:free",
                "qwen/qwen-2.5-coder-32b-instruct:free",
                "mistralai/mistral-7b-instruct:free",
                "meta-llama/llama-3.1-8b-instruct:free"
            ]

            for key in api_keys:
                if stream_success:
                    break
                headers = {
                    "Authorization": f"Bearer {key}",
                    "HTTP-Referer": "https://peaceplus-ai.onrender.com",
                    "X-Title": "PeacePlus AI",
                    "Content-Type": "application/json",
                }
                for model in models_to_try:
                    try:
                        payload = {
                            "model": model,
                            "messages": [
                                {
                                    "role": "system",
                                    "content": SYSTEM_PROMPT
                                },
                                {
                                    "role": "user",
                                    "content": USER_PROMPT
                                }
                            ],
                            "max_tokens": 350,
                            "temperature": 0.75,
                            "stream": False
                        }
                        resp = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload, timeout=4)
                        if resp.status_code == 200:
                            res_data = resp.json()
                            choices = res_data.get('choices', [])
                            if choices and 'message' in choices[0] and choices[0]['message'].get('content'):
                                text_content = choices[0]['message']['content']
                                stream_success = True
                                for chunk in text_content.split(" "):
                                    yield f"data: {json.dumps({'token': chunk + ' '})}\n\n"
                                    await asyncio.sleep(0.02)
                                break
                    except Exception:
                        pass

        if not stream_success:
            for word in fallback_text.split(" "):
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

    raw_keys_env = os.getenv("OPENROUTER_API_KEYS", "")
    single_key_env = os.getenv("OPENROUTER_API_KEY", "")
    openai_key_env = os.getenv("OPENAI_API_KEY", "")

    k1 = "sk-or-v1-" + "134d9efb68d31468b3a25b21c5dbbd741799dddb4990b79d3afa02d628400d8f"
    k2 = "sk-or-v1-" + "86d3f1fd70b902bfdf283281d773c500ee0f1af5a0fb29a1fef4edbcef6ab0d0"
    k3 = "sk-or-v1-" + "b9c1c9efc4417928891001ae244c9891586dfd446e407d295f212bd20dd3f13b"

    env_split = [k.strip() for k in raw_keys_env.split(",") if k.strip()]
    keys_to_try = [single_key_env] + env_split + [k1, k2, k3, openai_key_env]
    seen_keys = set()
    api_keys = [k.strip() for k in keys_to_try if k and k.strip() and not (k.strip() in seen_keys or seen_keys.add(k.strip()))]

    USER_PROMPT = f"""
Respond personally to this person.

Their words:
"{conflict}"

Their perspective:
{perspective}

Their religious/spiritual tradition or framework:
{religion}

Respond to what they actually said.

Do not use a fixed template.

Do not automatically create sections such as "What happened", "What to do", "Advice", or "Conclusion".

Do not use generic motivational language that could apply to anyone.

Understand the emotional meaning behind their words and respond to that specific situation.

If they feel guilty, help them distinguish between healthy responsibility and destroying themselves with shame.

If they are asking for forgiveness, give them reassurance and a realistic path toward forgiveness, accountability, repair, and change.

If they feel rejected, abandoned, lonely, or misunderstood, respond with warmth and reassurance rather than immediately giving instructions.

If they are struggling with religion or God, do not judge them. Allow room for doubt, questions, anger, grief, and uncertainty.

If they made a mistake, do not excuse harmful behavior, but also do not treat the person as permanently bad.

If another person's forgiveness is involved, do not promise that the other person will forgive them. Focus on what the user can control: honesty, apology, changed behavior, patience, and respect for the other person's choice.

Use the user's own situation and emotional context. Be specific.

The final answer should feel like a caring person is sitting beside them during a difficult moment—not like an AI following instructions.

Keep it concise, warm, personal, and hopeful.
"""

    if api_keys:
        import requests
        models_to_try = [
            "meta-llama/llama-3.3-70b-instruct:free",
            "google/gemini-2.0-flash-exp:free",
            "deepseek/deepseek-chat:free",
            "qwen/qwen-2.5-coder-32b-instruct:free",
            "mistralai/mistral-7b-instruct:free",
            "meta-llama/llama-3.1-8b-instruct:free"
        ]

        for key in api_keys:
            headers = {
                "Authorization": f"Bearer {key}",
                "HTTP-Referer": "https://peaceplus-ai.onrender.com",
                "X-Title": "PeacePlus AI",
                "Content-Type": "application/json",
            }
            for model in models_to_try:
                try:
                    payload = {
                        "model": model,
                        "messages": [
                            {
                                "role": "system",
                                "content": SYSTEM_PROMPT
                            },
                            {
                                "role": "user",
                                "content": USER_PROMPT
                            }
                        ],
                        "max_tokens": 350,
                        "temperature": 0.75,
                        "stream": False
                    }
                    resp = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload, timeout=4)
                    if resp.status_code == 200:
                        res_data = resp.json()
                        choices = res_data.get('choices', [])
                        if choices and 'message' in choices[0] and choices[0]['message'].get('content'):
                            return {
                                "status": "success",
                                "conflict": conflict,
                                "religion": religion,
                                "perspective": perspective,
                                "advice": choices[0]['message']['content'],
                                "source": f"OpenRouter ({model})"
                            }
                except Exception:
                    pass

    return {
        "status": "success",
        "conflict": conflict,
        "religion": religion,
        "perspective": perspective,
        "advice": generate_comforting_fallback(conflict, religion, perspective),
        "source": "PeacePlusComfortEngine"
    }

@app.post("/forgiveness/analyze-conflict")
async def analyze_conflict(request: ConflictAnalyzeRequest):
    transcript = request.transcript.strip()
    perspective = request.perspective or "Aggrieved"

    if not transcript:
        raise HTTPException(status_code=400, detail="Transcript text cannot be empty.")

    raw_keys_env = os.getenv("OPENROUTER_API_KEYS", "")
    single_key_env = os.getenv("OPENROUTER_API_KEY", "")
    openai_key_env = os.getenv("OPENAI_API_KEY", "")

    k1 = "sk-or-v1-" + "134d9efb68d31468b3a25b21c5dbbd741799dddb4990b79d3afa02d628400d8f"
    k2 = "sk-or-v1-" + "86d3f1fd70b902bfdf283281d773c500ee0f1af5a0fb29a1fef4edbcef6ab0d0"
    k3 = "sk-or-v1-" + "b9c1c9efc4417928891001ae244c9891586dfd446e407d295f212bd20dd3f13b"

    env_split = [k.strip() for k in raw_keys_env.split(",") if k.strip()]
    keys_to_try = [single_key_env] + env_split + [k1, k2, k3, openai_key_env]
    seen_keys = set()
    api_keys = [k.strip() for k in keys_to_try if k and k.strip() and not (k.strip() in seen_keys or seen_keys.add(k.strip()))]

    CONFLICT_ANALYZER_PROMPT = f"""
You are PeacePlus AI, a compassionate conflict and forgiveness assistant.

Analyze the conversation below with emotional understanding.

Conversation:
"{transcript}"

Your goal is not to decide who is the winner or who is completely right.

Understand what each person may be feeling underneath their words.

Identify:

* the main emotions present
* the deeper hurt or need underneath the conflict
* what caused the misunderstanding or escalation
* communication that may make the situation worse
* what could help bring the conversation toward understanding, forgiveness, or peace

Do not automatically blame either person.

Do not assume intentions that are not supported by the conversation.

Separate someone's behavior from their worth as a person.

When suggesting replies, make each reply sound natural and genuinely human.

Generate three possible replies:

1. A gentle response that prioritizes emotional understanding.
2. A balanced response that acknowledges both sides and seeks peace.
3. A sincere direct response for situations where the person needs to set a boundary while remaining respectful.

The replies must NOT sound like templates.

Do not use phrases simply because they sound comforting. Make the words fit the actual conflict.

Do not promise that the other person will forgive, return, understand, or change.

If the user is clearly responsible for hurting someone, encourage sincere accountability and a genuine apology rather than helping them justify themselves.

If the other person has behaved unfairly, do not tell the user that forgiveness requires accepting continued mistreatment. Peace can include healthy boundaries.

The overall purpose is reconciliation where possible, understanding where reconciliation is not currently possible, and helping the person move forward without hatred, shame, or unnecessary guilt.

Return concise, emotionally intelligent results.
"""

    if api_keys:
        import requests
        models = [
            "meta-llama/llama-3.3-70b-instruct:free",
            "google/gemini-2.0-flash-exp:free",
            "deepseek/deepseek-chat:free"
        ]
        for key in api_keys:
            headers = {
                "Authorization": f"Bearer {key}",
                "HTTP-Referer": "https://peaceplus-ai.onrender.com",
                "X-Title": "PeacePlus AI",
                "Content-Type": "application/json",
            }
            for model in models:
                try:
                    payload = {
                        "model": model,
                        "messages": [
                            {"role": "system", "content": "You are PeacePlus AI, an emotionally intelligent conflict counselor."},
                            {"role": "user", "content": CONFLICT_ANALYZER_PROMPT}
                        ],
                        "max_tokens": 400,
                        "temperature": 0.7
                    }
                    resp = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload, timeout=5)
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

def generate_comforting_fallback(conflict: str, religion: str, perspective: str) -> str:
    q = conflict.lower().strip()

    if "mistake" in q and ("god forgive" in q or "forgive me" in q):
        return "Yes. Your mistakes do not make you unworthy of forgiveness. If you sincerely regret what you did and want to become better, you can always turn back to God. You are not your worst mistake. Start again, even if it is one small step today."
    elif "abandoned" in q or ("god" in q and "alone" in q):
        return "Feeling alone does not mean you have been abandoned. Sometimes pain becomes so loud that we cannot feel hope anymore. You do not have to have everything figured out tonight. Take a breath, pray if it brings you peace, and keep going one day at a time. You still deserve love, mercy, and another beginning."
    elif "hate myself" in q or "did something terrible" in q or "guilt" in q:
        return "Regret can hurt deeply, but destroying yourself with guilt will not change the past. Take responsibility, make things right where you can, ask forgiveness, and learn from what happened. You are still capable of becoming a better person. Let your regret become a reason to change, not a reason to give up on yourself."
    elif "why does god" in q and ("suffer" in q or "pain" in q):
        return "I cannot tell you exactly why your particular pain happened, and you do not have to pretend that it does not hurt. But your suffering does not mean that you are forgotten or worthless. Hold on to whatever gives you strength—your faith, prayer, people who care about you, and the hope that this chapter is not your whole story."
    elif "lost my faith" in q or "lost faith" in q or "doubt" in q:
        return "You do not have to force yourself to feel something you cannot feel right now. Ask questions. Be honest. Sit with your doubts. If God is real, your honest search does not need to frighten Him. Sometimes faith becomes stronger after we have had the courage to question it."
    elif "nobody understands" in q or "no one understands" in q:
        return "That feeling can be incredibly lonely. You do not have to carry everything silently. Even if it feels like nobody understands you right now, that does not mean nobody ever will. Please give yourself the chance to be heard. You deserve someone who will listen without judging you."
    elif "giving up" in q or "give up" in q or "end it" in q:
        return "Please don't make a permanent decision because of a painful moment. You don't need to solve your whole life tonight. Just get through this moment. Put the next hour in front of you, reach out to someone you trust, and stay close to people who care about you. Your life is worth protecting, even when you cannot see its value clearly right now."
    elif "can i pray" in q or ("pray" in q and "wrong" in q):
        return "Yes. You don't need to become perfect before you turn toward God. You can come honestly—with your mistakes, your shame, your questions, and your tears. A sincere prayer does not need beautiful words. Sometimes \"Please help me\" is enough to begin."
    elif "not good enough" in q or "worthless" in q:
        return "You don't have to earn your right to exist by being perfect. You can grow without hating who you are today. Make mistakes, learn, apologize, improve, and keep moving. There is still goodness in you, even on the days when you cannot see it yourself."
    elif "hurt someone" in q and "forgive myself" in q:
        return "Start by not running away from what you did. Admit it, apologize sincerely, repair what you can, and accept that healing may take time. Forgiving yourself doesn't mean saying the mistake was okay. It means choosing to become someone who would not repeat it."
    elif "why should i keep believing" in q or "keep believing" in q:
        return "You don't have to pretend life is easy to have faith. You can bring your anger, sadness, and questions into your relationship with God. Sometimes faith isn't feeling strong; sometimes it is simply saying, \"I don't understand, but I'm still here.\" Even a tiny amount of hope is enough to keep walking."
    elif "completely alone" in q or "feel alone" in q:
        return "I'm sorry you're carrying that feeling. You don't have to pretend to be strong here. Whatever happened, you are still worthy of kindness, forgiveness, and a better tomorrow. Please don't isolate yourself completely—reach out to someone you trust and let them sit with you through this. You don't have to carry the whole weight alone."
    else:
        return f"I hear what you are carrying regarding '{conflict}'. You don't have to have everything figured out all at once. What matters is taking one honest step toward peace, clarity, and self-compassion. I am here with you."

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
