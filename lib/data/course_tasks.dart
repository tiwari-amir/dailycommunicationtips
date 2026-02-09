class DailyTask {
  final int level;
  final int taskNumber;
  final int totalTasks;
  final String content;

  DailyTask({
    required this.level,
    required this.taskNumber,
    required this.totalTasks,
    required this.content,
  });
}

final List<DailyTask> allTasks = [

  // ===== LEVEL 1 (5 tasks) =====
  DailyTask(
    level: 1,
    taskNumber: 1,
    totalTasks: 5,
    content: 'Today, speak slowly and mindfully. Focus on your breathing before you begin to talk. Calm speech helps others understand you better and builds your confidence. Notice how your breath influences your tone and clarity.',
  ),
  DailyTask(
    level: 1,
    taskNumber: 2,
    totalTasks: 5,
    content: 'Today, practice active listening. Give your full attention to the speaker without interrupting. Notice their words, tone, and pauses. Respond only after they finish. This strengthens understanding and connection.',
  ),
  DailyTask(
    level: 1,
    taskNumber: 3,
    totalTasks: 5,
    content: 'Today, reword something you said earlier in simpler terms. Practice clarity by eliminating filler words. Speak as if your listener has never heard the idea before.',
  ),
  DailyTask(
    level: 1,
    taskNumber: 4,
    totalTasks: 5,
    content: 'Today, add warmth to your tone. Smile naturally as you speak and observe how your words feel softer and more engaging. Warmth invites trust.',
  ),
  DailyTask(
    level: 1,
    taskNumber: 5,
    totalTasks: 5,
    content: 'Today, end a conversation with a thoughtful question that invites more dialogue. Notice how this shows interest and encourages deeper engagement.',
  ),

  // ===== LEVEL 2 (6 tasks) =====
  DailyTask(
    level: 2,
    taskNumber: 1,
    totalTasks: 6,
    content: 'Today, in every conversation, identify one moment where you could have listened more fully. Make a mental note to pause and truly absorb information before responding.',
  ),
  DailyTask(
    level: 2,
    taskNumber: 2,
    totalTasks: 6,
    content: 'Today, speak about something you’re passionate about in two sentences. Focus on clarity and enthusiasm, not speed. See how intentional pacing helps others follow your thoughts.',
  ),
  DailyTask(
    level: 2,
    taskNumber: 3,
    totalTasks: 6,
    content: 'Today, practice summarizing someone’s point before you reply. Saying “So what you mean is…” shows you are fully listening and helps avoid misunderstandings.',
  ),
  DailyTask(
    level: 2,
    taskNumber: 4,
    totalTasks: 6,
    content: 'Today, pay attention to your body language. Ensure your posture is open and relaxed. Nonverbal cues greatly impact how your message is received.',
  ),
  DailyTask(
    level: 2,
    taskNumber: 5,
    totalTasks: 6,
    content: 'Today, rephrase a complex idea you shared earlier into simpler terms. Practicing simplification enhances clarity.',
  ),
  DailyTask(
    level: 2,
    taskNumber: 6,
    totalTasks: 6,
    content: 'Today, reflect on a recent conversation that felt awkward. Identify one thing you can do differently next time to improve connection.',
  ),

  // ===== LEVEL 3 (6 tasks) =====
  DailyTask(
    level: 3,
    taskNumber: 1,
    totalTasks: 6,
    content: 'Today, practice “mirroring” in conversation — repeat a key phrase the speaker uses to show understanding. This encourages deeper dialogue and builds rapport.',
  ),
  DailyTask(
    level: 3,
    taskNumber: 2,
    totalTasks: 6,
    content: 'Today, speak for one minute on a topic you find challenging. Record your tone and clarity. Then reflect on what made it difficult and how to improve.',
  ),
  DailyTask(
    level: 3,
    taskNumber: 3,
    totalTasks: 6,
    content: 'Today, acknowledge emotions in conversation. When someone expresses frustration or joy, name the feeling before responding. This strengthens empathy.',
  ),
  DailyTask(
    level: 3,
    taskNumber: 4,
    totalTasks: 6,
    content: 'Today, replace any negative self‑talk before speaking with positive affirmations. Confidence in yourself reflects in your communication.',
  ),
  DailyTask(
    level: 3,
    taskNumber: 5,
    totalTasks: 6,
    content: 'Today, practice pausing for three seconds before you answer a question. This gives time for thoughtful response instead of reacting reflexively.',
  ),
  DailyTask(
    level: 3,
    taskNumber: 6,
    totalTasks: 6,
    content: 'Today, practice listening without judgment. Notice when your mind forms an opinion before the speaker finishes, and gently bring focus back to listening.',
  ),

  // ===== LEVEL 4 (7 tasks) =====
  DailyTask(
    level: 4,
    taskNumber: 1,
    totalTasks: 7,
    content: 'Today, practice acknowledging differences in conversation — say “I hear your perspective, and…” before contributing your own thoughts. This encourages respect and collaboration.',
  ),
  DailyTask(
    level: 4,
    taskNumber: 2,
    totalTasks: 7,
    content: 'Today, share a personal experience that illustrates a point you want to make. Storytelling makes your communication memorable.',
  ),
  DailyTask(
    level: 4,
    taskNumber: 3,
    totalTasks: 7,
    content: 'Today, practice structured speaking: state your conclusion first, then give supporting details. This helps audiences follow your reasoning.',
  ),
  DailyTask(
    level: 4,
    taskNumber: 4,
    totalTasks: 7,
    content: 'Today, practice communicating appreciation to someone. Read your message aloud before sending to ensure warmth and sincerity.',
  ),
  DailyTask(
    level: 4,
    taskNumber: 5,
    totalTasks: 7,
    content: 'Today, observe your pace. If you tend to rush, consciously slow down. If you speak slowly, focus on clarity over length.',
  ),
  DailyTask(
    level: 4,
    taskNumber: 6,
    totalTasks: 7,
    content: 'Today, notice your emotional responses when someone disagrees with you. Practice staying calm and responding respectfully.',
  ),
  DailyTask(
    level: 4,
    taskNumber: 7,
    totalTasks: 7,
    content: 'Today, practice active listening with a friend: summarize their main point and ask one follow‑up question.',
  ),

  // ===== LEVEL 5 (7 tasks) =====
  DailyTask(
    level: 5,
    taskNumber: 1,
    totalTasks: 7,
    content: 'Today, practice asking powerful open‑ended questions like “What led you to that idea?” to deepen conversations.',
  ),
  DailyTask(
    level: 5,
    taskNumber: 2,
    totalTasks: 7,
    content: 'Today, focus on tone variation to emphasize key points in your speech. Variation keeps your audience engaged.',
  ),
  DailyTask(
    level: 5,
    taskNumber: 3,
    totalTasks: 7,
    content: 'Today, observe your listening habits: do you interrupt? Practice waiting until the speaker pauses before replying.',
  ),
  DailyTask(
    level: 5,
    taskNumber: 4,
    totalTasks: 7,
    content: 'Today, rephrase feedback you receive in positive, actionable terms before you respond.',
  ),
  DailyTask(
    level: 5,
    taskNumber: 5,
    totalTasks: 7,
    content: 'Today, practice expressing appreciation to someone — be specific about what you value.',
  ),
  DailyTask(
    level: 5,
    taskNumber: 6,
    totalTasks: 7,
    content: 'Today, notice whether your body language matches your words. Adjust to ensure consistency.',
  ),
  DailyTask(
    level: 5,
    taskNumber: 7,
    totalTasks: 7,
    content: 'Today, practice summarizing an idea in one sentence before elaborating. Clarity builds confidence.',
  ),

  // ===== LEVEL 6 (8 tasks) =====
  DailyTask(
    level: 6,
    taskNumber: 1,
    totalTasks: 8,
    content: 'Today, practice reflective listening: repeat the speaker’s idea in your own words before responding with your insights.',
  ),
  DailyTask(
    level: 6,
    taskNumber: 2,
    totalTasks: 8,
    content: 'Today, focus on confidence‑building phrases like “Here’s what I mean…” and “Let me explain…” to organize your speech.',
  ),
  DailyTask(
    level: 6,
    taskNumber: 3,
    totalTasks: 8,
    content: 'Today, practice pausing before replying to ensure your response is thoughtful, not rushed.',
  ),
  DailyTask(
    level: 6,
    taskNumber: 4,
    totalTasks: 8,
    content: 'Today, observe how your tone shifts when you discuss something emotional. Practice maintaining calm while still being authentic.',
  ),
  DailyTask(
    level: 6,
    taskNumber: 5,
    totalTasks: 8,
    content: 'Today, ask a colleague or friend for feedback on your communication and reflect on it without defensiveness.',
  ),
  DailyTask(
    level: 6,
    taskNumber: 6,
    totalTasks: 8,
    content: 'Today, practice summarizing a conversation you had earlier and identify one way you could improve your communication next time.',
  ),
  DailyTask(
    level: 6,
    taskNumber: 7,
    totalTasks: 8,
    content: 'Today, notice moments when you use fillers (“um,” “like”). Consciously reduce them for clearer speech.',
  ),
  DailyTask(
    level: 6,
    taskNumber: 8,
    totalTasks: 8,
    content: 'Today, practice delivering one point with supportive examples rather than abstract statements for clarity.',
  ),

  // ===== LEVEL 7 (8 tasks) =====
  DailyTask(
    level: 7,
    taskNumber: 1,
    totalTasks: 8,
    content: 'Today, practice adjusting your message to your listener’s perspective. Tailor your words to their level of understanding.',
  ),
  DailyTask(
    level: 7,
    taskNumber: 2,
    totalTasks: 8,
    content: 'Today, focus on maintaining eye contact appropriately to build engagement and trust.',
  ),
  DailyTask(
    level: 7,
    taskNumber: 3,
    totalTasks: 8,
    content: 'Today, keep your responses concise. Aim for clear communication without unnecessary detail.',
  ),
  DailyTask(
    level: 7,
    taskNumber: 4,
    totalTasks: 8,
    content: 'Today, practice expressing your needs clearly without apology or defensiveness.',
  ),
  DailyTask(
    level: 7,
    taskNumber: 5,
    totalTasks: 8,
    content: 'Today, observe another speaker you admire and note what makes their communication effective.',
  ),
  DailyTask(
    level: 7,
    taskNumber: 6,
    totalTasks: 8,
    content: 'Today, practice framing difficult feedback as a future opportunity rather than a criticism.',
  ),
  DailyTask(
    level: 7,
    taskNumber: 7,
    totalTasks: 8,
    content: 'Today, practice asking summarizing questions to ensure shared understanding.',
  ),
  DailyTask(
    level: 7,
    taskNumber: 8,
    totalTasks: 8,
    content: 'Today, focus on speaking with steady volume and clear articulation to enhance your presence.',
  ),

  // ===== LEVEL 8 (9 tasks) =====
  DailyTask(
    level: 8,
    taskNumber: 1,
    totalTasks: 9,
    content: 'Today, practice paraphrasing complex ideas in simple terms to ensure understanding.',
  ),
  DailyTask(
    level: 8,
    taskNumber: 2,
    totalTasks: 9,
    content: 'Today, practice sharing your feedback using the “praise sandwich”: positive, improvement, positive.',
  ),
  DailyTask(
    level: 8,
    taskNumber: 3,
    totalTasks: 9,
    content: 'Today, notice when you judge before listening fully. Consciously delay judgment to improve understanding.',
  ),
  DailyTask(
    level: 8,
    taskNumber: 4,
    totalTasks: 9,
    content: 'Today, focus on delivering your message with calm and assertive body language.',
  ),
  DailyTask(
    level: 8,
    taskNumber: 5,
    totalTasks: 9,
    content: 'Today, practice framing your ideas with clear transitions like “first,” “next,” “finally.”',
  ),
  DailyTask(
    level: 8,
    taskNumber: 6,
    totalTasks: 9,
    content: 'Today, practice active listening by reflecting both content and emotion (“It sounds like you feel…”).',
  ),
  DailyTask(
    level: 8,
    taskNumber: 7,
    totalTasks: 9,
    content: 'Today, speak aloud one idea you want to communicate clearly, then rewrite it in simpler form.',
  ),
  DailyTask(
    level: 8,
    taskNumber: 8,
    totalTasks: 9,
    content: 'Today, focus on reducing distractions (phone, noise) to improve communication focus.',
  ),
  DailyTask(
    level: 8,
    taskNumber: 9,
    totalTasks: 9,
    content: 'Today, practice closing a conversation with a clear takeaway or next step.',
  ),

  // ===== LEVEL 9 (9 tasks) =====
  DailyTask(
    level: 9,
    taskNumber: 1,
    totalTasks: 9,
    content: 'Today, practice expressing appreciation with specific details about what you value.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 2,
    totalTasks: 9,
    content: 'Today, focus on balancing speaking and listening proportionally in a conversation.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 3,
    totalTasks: 9,
    content: 'Today, practice silence after asking a question — allow space for thoughtful response.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 4,
    totalTasks: 9,
    content: 'Today, reframe challenging feedback into goal‑oriented language for constructive dialogue.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 5,
    totalTasks: 9,
    content: 'Today, focus on maintaining consistent eye contact to build trust and engagement.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 6,
    totalTasks: 9,
    content: 'Today, practice summarizing the key point of a discussion before ending it.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 7,
    totalTasks: 9,
    content: 'Today, observe your tone in a conversation and adjust to maintain calm engagement.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 8,
    totalTasks: 9,
    content: 'Today, practice connecting emotionally before offering advice.',
  ),
  DailyTask(
    level: 9,
    taskNumber: 9,
    totalTasks: 9,
    content: 'Today, describe an idea in one sentence, then expand with two supporting points.',
  ),

// ===== LEVEL 10 (10 tasks) =====
DailyTask(
    level: 10,
    taskNumber: 1,
    totalTasks: 10,
    content: 'Today, practice asking clarifying questions to fully understand someone’s perspective.',
),
DailyTask(
    level: 10,
    taskNumber: 2,
    totalTasks: 10,
    content: 'Today, summarize your main point before elaborating with examples for clarity.',
),
DailyTask(
    level: 10,
    taskNumber: 3,
    totalTasks: 10,
    content: 'Today, notice your pace. Slow down or speed up intentionally to match your message’s importance.',
),
DailyTask(
    level: 10,
    taskNumber: 4,
    totalTasks: 10,
    content: 'Today, practice delivering constructive criticism using positive, specific language.',
),
DailyTask(
    level: 10,
    taskNumber: 5,
    totalTasks: 10,
    content: 'Today, practice acknowledging others’ emotions before giving your response.',
),
DailyTask(
    level: 10,
    taskNumber: 6,
    totalTasks: 10,
    content: 'Today, engage in a short conversation and practice reflecting both content and feeling.',
),
DailyTask(
    level: 10,
    taskNumber: 7,
    totalTasks: 10,
    content: 'Today, practice connecting ideas with clear transitions: “first,” “next,” “finally.”',
),
DailyTask(
    level: 10,
    taskNumber: 8,
    totalTasks: 10,
    content: 'Today, practice giving a concise one-minute explanation of a topic you know well.',
),
DailyTask(
    level: 10,
    taskNumber: 9,
    totalTasks: 10,
    content: 'Today, observe a conversation and notice body language and tone. Reflect on effectiveness.',
),
DailyTask(
    level: 10,
    taskNumber: 10,
    totalTasks: 10,
    content: 'Today, ask one open-ended question and practice listening without interrupting for two minutes.',
),

// ===== LEVEL 11 (10 tasks) =====
DailyTask(
    level: 11,
    taskNumber: 1,
    totalTasks: 10,
    content: 'Today, practice structuring a short argument with a clear introduction, reasoning, and conclusion.',
),
DailyTask(
    level: 11,
    taskNumber: 2,
    totalTasks: 10,
    content: 'Today, notice filler words and consciously replace them with silent pauses for clarity.',
),
DailyTask(
    level: 11,
    taskNumber: 3,
    totalTasks: 10,
    content: 'Today, provide one piece of specific, actionable feedback to a colleague or friend.',
),
DailyTask(
    level: 11,
    taskNumber: 4,
    totalTasks: 10,
    content: 'Today, practice responding to disagreement with calm, assertive language.',
),
DailyTask(
    level: 11,
    taskNumber: 5,
    totalTasks: 10,
    content: 'Today, summarize a conversation’s key points to ensure mutual understanding.',
),
DailyTask(
    level: 11,
    taskNumber: 6,
    totalTasks: 10,
    content: 'Today, speak on a complex topic using examples to simplify your explanation.',
),
DailyTask(
    level: 11,
    taskNumber: 7,
    totalTasks: 10,
    content: 'Today, practice maintaining warm tone and eye contact while giving feedback.',
),
DailyTask(
    level: 11,
    taskNumber: 8,
    totalTasks: 10,
    content: 'Today, actively listen and paraphrase what you heard before responding.',
),
DailyTask(
    level: 11,
    taskNumber: 9,
    totalTasks: 10,
    content: 'Today, note any moments you react emotionally. Pause and respond thoughtfully.',
),
DailyTask(
    level: 11,
    taskNumber: 10,
    totalTasks: 10,
    content: 'Today, practice structuring your ideas in bullet points when explaining something important.', 
),

// ===== LEVEL 12 (11 tasks) =====
DailyTask(
    level: 12,
    taskNumber: 1,
    totalTasks: 11,
    content: 'Today, practice framing difficult topics with a solution-focused mindset.',
),
DailyTask(
    level: 12,
    taskNumber: 2,
    totalTasks: 11,
    content: 'Today, actively listen and note nonverbal cues to understand the full message.',
),
DailyTask(
    level: 12,
    taskNumber: 3,
    totalTasks: 11,
    content: 'Today, practice delivering your opinion respectfully, even if it differs from others.',
),
DailyTask(
    level: 12,
    taskNumber: 4,
    totalTasks: 11,
    content: 'Today, summarize a complex idea in three sentences to improve conciseness.',
),
DailyTask(
    level: 12,
    taskNumber: 5,
    totalTasks: 11,
    content: 'Today, notice and reduce interruptions when others speak.',
),
DailyTask(
    level: 12,
    taskNumber: 6,
    totalTasks: 11,
    content: 'Today, practice expressing gratitude with specific examples to improve relational communication.',
),
DailyTask(
    level: 12,
    taskNumber: 7,
    totalTasks: 11,
    content: 'Today, practice paraphrasing feedback to show understanding before responding.',
),
DailyTask(
    level: 12,
    taskNumber: 8,
    totalTasks: 11,
    content: 'Today, focus on calm and confident posture during conversations.',
),
DailyTask(
    level: 12,
    taskNumber: 9,
    totalTasks: 11,
    content: 'Today, practice summarizing multiple perspectives in one concise paragraph.',
),
DailyTask(
    level: 12,
    taskNumber: 10,
    totalTasks: 11,
    content: 'Today, ask reflective questions like “How do you feel about this outcome?”',
),
DailyTask(
    level: 12,
    taskNumber: 11,
    totalTasks: 11,
    content: 'Today, practice delivering your message using “I” statements to avoid blame.', 
),

// ===== LEVEL 13 (11 tasks) =====
DailyTask(
    level: 13,
    taskNumber: 1,
    totalTasks: 11,
    content: 'Today, practice active empathy: verbalize the emotion you perceive before responding.',
),
DailyTask(
    level: 13,
    taskNumber: 2,
    totalTasks: 11,
    content: 'Today, practice giving concise, confident explanations in meetings or group conversations.',
),
DailyTask(
    level: 13,
    taskNumber: 3,
    totalTasks: 11,
    content: 'Today, observe your voice modulation to keep listeners engaged.',
),
DailyTask(
    level: 13,
    taskNumber: 4,
    totalTasks: 11,
    content: 'Today, practice summarizing conversations to ensure clarity and mutual understanding.',
),
DailyTask(
    level: 13,
    taskNumber: 5,
    totalTasks: 11,
    content: 'Today, focus on respectful disagreement, articulating both sides before sharing your view.',
),
DailyTask(
    level: 13,
    taskNumber: 6,
    totalTasks: 11,
    content: 'Today, practice structuring presentations with a clear introduction, main points, and conclusion.',
),
DailyTask(
    level: 13,
    taskNumber: 7,
    totalTasks: 11,
    content: 'Today, notice any rushed speech; slow down to ensure clarity and confidence.',
),
DailyTask(
    level: 13,
    taskNumber: 8,
    totalTasks: 11,
    content: 'Today, actively use examples or analogies to clarify complex points.',
),
DailyTask(
    level: 13,
    taskNumber: 9,
    totalTasks: 11,
    content: 'Today, listen to feedback without interrupting, then restate your understanding before responding.',
),
DailyTask(
    level: 13,
    taskNumber: 10,
    totalTasks: 11,
    content: 'Today, express appreciation and recognition during a conversation to strengthen connection.',
),
DailyTask(
    level: 13,
    taskNumber: 11,
    totalTasks: 11,
    content: 'Today, practice pausing intentionally before answering challenging questions for thoughtful responses.', 
),

// ===== LEVEL 14 (12 tasks) =====
DailyTask(
    level: 14,
    taskNumber: 1,
    totalTasks: 12,
    content: 'Today, practice persuasive communication by presenting a viewpoint with clear reasoning and empathy.',
),
DailyTask(
    level: 14,
    taskNumber: 2,
    totalTasks: 12,
    content: 'Today, focus on maintaining a calm and confident tone in emotionally charged conversations.',
),
DailyTask(
    level: 14,
    taskNumber: 3,
    totalTasks: 12,
    content: 'Today, structure your points in a logical sequence to improve understanding.',
),
DailyTask(
    level: 14,
    taskNumber: 4,
    totalTasks: 12,
    content: 'Today, reflect on feedback received previously and plan improvements for your next conversation.',
),
DailyTask(
    level: 14,
    taskNumber: 5,
    totalTasks: 12,
    content: 'Today, practice summarizing a discussion in one or two sentences for clarity.',
),
DailyTask(
    level: 14,
    taskNumber: 6,
    totalTasks: 12,
    content: 'Today, notice your nonverbal cues and adjust them to support your verbal message.',
),
DailyTask(
    level: 14,
    taskNumber: 7,
    totalTasks: 12,
    content: 'Today, practice asking follow-up questions to encourage deeper sharing.',
),
DailyTask(
    level: 14,
    taskNumber: 8,
    totalTasks: 12,
    content: 'Today, deliver one short message with confidence, clarity, and warmth.',
),
DailyTask(
    level: 14,
    taskNumber: 9,
    totalTasks: 12,
    content: 'Today, practice empathetic listening and validate the speaker’s feelings before responding.',
),
DailyTask(
    level: 14,
    taskNumber: 10,
    totalTasks: 12,
    content: 'Today, use concise examples to clarify abstract ideas in conversation.',
),
DailyTask(
    level: 14,
    taskNumber: 11,
    totalTasks: 12,
    content: 'Today, consciously reduce negative self-talk when preparing to speak.',
),
DailyTask(
    level: 14,
    taskNumber: 12,
    totalTasks: 12,
    content: 'Today, close a conversation with a key takeaway or next step for clarity.', 
),

// ===== LEVEL 15 (12 tasks) =====
DailyTask(
    level: 15,
    taskNumber: 1,
    totalTasks: 12,
    content: 'Today, focus on listening deeply and reflecting the essence of what is being said.',
),
DailyTask(
    level: 15,
    taskNumber: 2,
    totalTasks: 12,
    content: 'Today, practice using affirmations in conversation to boost confidence and clarity.',
),
DailyTask(
    level: 15,
    taskNumber: 3,
    totalTasks: 12,
    content: 'Today, summarize complex information in three simple sentences.',
),
DailyTask(
    level: 15,
    taskNumber: 4,
    totalTasks: 12,
    content: 'Today, practice handling disagreements with calm, constructive responses.',
),
DailyTask(
    level: 15,
    taskNumber: 5,
    totalTasks: 12,
    content: 'Today, observe your tone and adjust to maintain engagement and warmth.',
),
DailyTask(
    level: 15,
    taskNumber: 6,
    totalTasks: 12,
    content: 'Today, practice giving feedback that is specific, actionable, and positive.',
),
DailyTask(
    level: 15,
    taskNumber: 7,
    totalTasks: 12,
    content: 'Today, deliver one idea clearly and slowly, focusing on enunciation and clarity.',
),
DailyTask(
    level: 15,
    taskNumber: 8,
    totalTasks: 12,
    content: 'Today, practice asking questions to clarify assumptions before responding.',
),
DailyTask(
    level: 15,
    taskNumber: 9,
    totalTasks: 12,
    content: 'Today, observe your posture and gestures to ensure they support your message.',
),
DailyTask(
    level: 15,
    taskNumber: 10,
    totalTasks: 12,
    content: 'Today, practice active listening by repeating back the main idea before giving your response.',
),
DailyTask(
    level: 15,
    taskNumber: 11,
    totalTasks: 12,
    content: 'Today, frame your points with clear transitions to improve comprehension.',
),
DailyTask(
    level: 15,
    taskNumber: 12,
    totalTasks: 12,
    content: 'Today, focus on expressing gratitude clearly and genuinely in a conversation.', 
),

// ===== LEVEL 16 (13 tasks) =====
DailyTask(
    level: 16,
    taskNumber: 1,
    totalTasks: 13,
    content: 'Today, practice persuading someone using logic and empathy, not pressure.',
),
// … and continue similarly for all remaining tasks until Level 20

// ===== LEVEL 16 (13 tasks) =====
DailyTask(
    level: 16,
    taskNumber: 1,
    totalTasks: 13,
    content: 'Today, practice persuading someone using clear reasoning, empathy, and relevant examples.',
),
DailyTask(
    level: 16,
    taskNumber: 2,
    totalTasks: 13,
    content: 'Today, notice your body language during discussions and ensure it reinforces your message.',
),
DailyTask(
    level: 16,
    taskNumber: 3,
    totalTasks: 13,
    content: 'Today, practice listening without planning your response in advance to fully absorb information.',
),
DailyTask(
    level: 16,
    taskNumber: 4,
    totalTasks: 13,
    content: 'Today, use reflective statements: “It sounds like you feel…” to show empathy before responding.',
),
DailyTask(
    level: 16,
    taskNumber: 5,
    totalTasks: 13,
    content: 'Today, summarize a complex discussion in three sentences to ensure clarity.',
),
DailyTask(
    level: 16,
    taskNumber: 6,
    totalTasks: 13,
    content: 'Today, practice assertive communication by stating your opinion with confidence and respect.',
),
DailyTask(
    level: 16,
    taskNumber: 7,
    totalTasks: 13,
    content: 'Today, notice tone variations and use them intentionally to emphasize key points.',
),
DailyTask(
    level: 16,
    taskNumber: 8,
    totalTasks: 13,
    content: 'Today, practice giving feedback with both positive reinforcement and actionable suggestions.',
),
DailyTask(
    level: 16,
    taskNumber: 9,
    totalTasks: 13,
    content: 'Today, practice framing your ideas in a story format for better engagement and recall.',
),
DailyTask(
    level: 16,
    taskNumber: 10,
    totalTasks: 13,
    content: 'Today, practice pausing intentionally before difficult responses to maintain composure.',
),
DailyTask(
    level: 16,
    taskNumber: 11,
    totalTasks: 13,
    content: 'Today, notice any rushed speech and consciously slow down to improve clarity.',
),
DailyTask(
    level: 16,
    taskNumber: 12,
    totalTasks: 13,
    content: 'Today, practice asking follow-up questions to deepen understanding and dialogue.',
),
DailyTask(
    level: 16,
    taskNumber: 13,
    totalTasks: 13,
    content: 'Today, focus on expressing ideas clearly while adapting to your listener’s perspective.',
),

// ===== LEVEL 17 (13 tasks) =====
DailyTask(
    level: 17,
    taskNumber: 1,
    totalTasks: 13,
    content: 'Today, practice guiding a conversation by summarizing key points and asking clarifying questions.',
),
DailyTask(
    level: 17,
    taskNumber: 2,
    totalTasks: 13,
    content: 'Today, maintain calm and confidence in a discussion even when opinions differ.',
),
DailyTask(
    level: 17,
    taskNumber: 3,
    totalTasks: 13,
    content: 'Today, practice providing concise explanations for complex topics with examples.',
),
DailyTask(
    level: 17,
    taskNumber: 4,
    totalTasks: 13,
    content: 'Today, reflect on your previous conversations and identify one improvement for next time.',
),
DailyTask(
    level: 17,
    taskNumber: 5,
    totalTasks: 13,
    content: 'Today, practice framing challenging points with solutions and constructive suggestions.',
),
DailyTask(
    level: 17,
    taskNumber: 6,
    totalTasks: 13,
    content: 'Today, consciously manage your tone and pace to enhance engagement and clarity.',
),
DailyTask(
    level: 17,
    taskNumber: 7,
    totalTasks: 13,
    content: 'Today, practice summarizing multiple perspectives before providing your own opinion.',
),
DailyTask(
    level: 17,
    taskNumber: 8,
    totalTasks: 13,
    content: 'Today, notice nonverbal cues in others and respond appropriately to strengthen understanding.',
),
DailyTask(
    level: 17,
    taskNumber: 9,
    totalTasks: 13,
    content: 'Today, practice articulating your points using structured sentences for clarity.',
),
DailyTask(
    level: 17,
    taskNumber: 10,
    totalTasks: 13,
    content: 'Today, ask reflective questions: “How do you feel about this approach?”',
),
DailyTask(
    level: 17,
    taskNumber: 11,
    totalTasks: 13,
    content: 'Today, practice validating emotions before offering advice or suggestions.',
),
DailyTask(
    level: 17,
    taskNumber: 12,
    totalTasks: 13,
    content: 'Today, practice delivering a short persuasive argument with empathy and facts.',
),
DailyTask(
    level: 17,
    taskNumber: 13,
    totalTasks: 13,
    content: 'Today, observe how your body language, tone, and words align for maximum impact.', 
),

// ===== LEVEL 18 (14 tasks) =====
DailyTask(
    level: 18,
    taskNumber: 1,
    totalTasks: 14,
    content: 'Today, practice staying calm during emotionally charged conversations.',
),
DailyTask(
    level: 18,
    taskNumber: 2,
    totalTasks: 14,
    content: 'Today, focus on expressing ideas with precision and clarity.',
),
DailyTask(
    level: 18,
    taskNumber: 3,
    totalTasks: 14,
    content: 'Today, practice listening without judgment and reflect back what you heard.',
),
DailyTask(
    level: 18,
    taskNumber: 4,
    totalTasks: 14,
    content: 'Today, structure your points logically with introduction, details, and conclusion.',
),
DailyTask(
    level: 18,
    taskNumber: 5,
    totalTasks: 14,
    content: 'Today, practice summarizing others’ points before giving your response.',
),
DailyTask(
    level: 18,
    taskNumber: 6,
    totalTasks: 14,
    content: 'Today, maintain calm tone and steady pace even when receiving critical feedback.',
),
DailyTask(
    level: 18,
    taskNumber: 7,
    totalTasks: 14,
    content: 'Today, practice clarifying assumptions before responding to questions or challenges.',
),
DailyTask(
    level: 18,
    taskNumber: 8,
    totalTasks: 14,
    content: 'Today, practice framing feedback positively while remaining truthful.',
),
DailyTask(
    level: 18,
    taskNumber: 9,
    totalTasks: 14,
    content: 'Today, articulate your point using analogies or stories for easier understanding.',
),
DailyTask(
    level: 18,
    taskNumber: 10,
    totalTasks: 14,
    content: 'Today, consciously observe your posture and gestures to reinforce your message.',
),
DailyTask(
    level: 18,
    taskNumber: 11,
    totalTasks: 14,
    content: 'Today, practice summarizing complex discussions in concise points.',
),
DailyTask(
    level: 18,
    taskNumber: 12,
    totalTasks: 14,
    content: 'Today, practice asking open-ended questions to deepen engagement.',
),
DailyTask(
    level: 18,
    taskNumber: 13,
    totalTasks: 14,
    content: 'Today, practice giving structured presentations with clarity and calmness.',
),
DailyTask(
    level: 18,
    taskNumber: 14,
    totalTasks: 14,
    content: 'Today, notice moments of self-doubt and replace with confident, positive affirmations.', 
),

// ===== LEVEL 19 (14 tasks) =====
DailyTask(
    level: 19,
    taskNumber: 1,
    totalTasks: 14,
    content: 'Today, practice leading a conversation by summarizing points and asking guiding questions.',
),
DailyTask(
    level: 19,
    taskNumber: 2,
    totalTasks: 14,
    content: 'Today, actively manage your emotions to respond constructively in debates.',
),
DailyTask(
    level: 19,
    taskNumber: 3,
    totalTasks: 14,
    content: 'Today, practice concise explanations while maintaining engagement and warmth.',
),
DailyTask(
    level: 19,
    taskNumber: 4,
    totalTasks: 14,
    content: 'Today, observe and reflect on nonverbal cues to guide your communication style.',
),
DailyTask(
    level: 19,
    taskNumber: 5,
    totalTasks: 14,
    content: 'Today, practice summarizing diverse perspectives before giving your opinion.',
),
DailyTask(
    level: 19,
    taskNumber: 6,
    totalTasks: 14,
    content: 'Today, practice persuasive communication using logic and empathy together.',
),
DailyTask(
    level: 19,
    taskNumber: 7,
    totalTasks: 14,
    content: 'Today, maintain calm body language and confident tone during challenging conversations.',
),
DailyTask(
    level: 19,
    taskNumber: 8,
    totalTasks: 14,
    content: 'Today, practice active listening and verbalize understanding before responding.',
),
DailyTask(
    level: 19,
    taskNumber: 9,
    totalTasks: 14,
    content: 'Today, reflect on previous conversations and identify one area for improvement.',
),
DailyTask(
    level: 19,
    taskNumber: 10,
    totalTasks: 14,
    content: 'Today, frame challenging points positively with constructive suggestions.',
),
DailyTask(
    level: 19,
    taskNumber: 11,
    totalTasks: 14,
    content: 'Today, consciously pace your speech to enhance clarity and confidence.',
),
DailyTask(
    level: 19,
    taskNumber: 12,
    totalTasks: 14,
    content: 'Today, practice asking reflective questions: “How might we approach this differently?”',
),
DailyTask(
    level: 19,
    taskNumber: 13,
    totalTasks: 14,
    content: 'Today, observe alignment of your words, tone, and gestures for effective communication.',
),
DailyTask(
    level: 19,
    taskNumber: 14,
    totalTasks: 14,
    content: 'Today, practice concluding discussions with clear takeaways or next steps.', 
),

// ===== LEVEL 20 (15 tasks) =====
DailyTask(
    level: 20,
    taskNumber: 1,
    totalTasks: 15,
    content: 'Today, integrate all your communication skills: clarity, empathy, and confidence in one conversation.',
),
DailyTask(
    level: 20,
    taskNumber: 2,
    totalTasks: 15,
    content: 'Today, practice leading a discussion while ensuring everyone feels heard.',
),
DailyTask(
    level: 20,
    taskNumber: 3,
    totalTasks: 15,
    content: 'Today, deliver a message with precise language and engaging storytelling.',
),
DailyTask(
    level: 20,
    taskNumber: 4,
    totalTasks: 15,
    content: 'Today, observe your tone, gestures, and posture, ensuring they align with your words.',
),
DailyTask(
    level: 20,
    taskNumber: 5,
    totalTasks: 15,
    content: 'Today, handle challenging feedback with calm, thoughtful responses.',
),
DailyTask(
    level: 20,
    taskNumber: 6,
    totalTasks: 15,
    content: 'Today, practice concise explanations of complex ideas using relatable examples.',
),
DailyTask(
    level: 20,
    taskNumber: 7,
    totalTasks: 15,
    content: 'Today, actively reflect on conversations and identify actionable improvements.',
),
DailyTask(
    level: 20,
    taskNumber: 8,
    totalTasks: 15,
    content: 'Today, integrate active listening and empathy in every interaction.',
),
DailyTask(
    level: 20,
    taskNumber: 9,
    totalTasks: 15,
    content: 'Today, practice asking meaningful, open-ended questions to deepen discussions.',
),
DailyTask(
    level: 20,
    taskNumber: 10,
    totalTasks: 15,
    content: 'Today, summarize and convey key points clearly and confidently.',
),
DailyTask(
    level: 20,
    taskNumber: 11,
    totalTasks: 15,
    content: 'Today, maintain calm, confident presence while managing complex or emotional topics.',
),
DailyTask(
    level: 20,
    taskNumber: 12,
    totalTasks: 15,
    content: 'Today, deliver persuasive arguments using empathy, logic, and clarity.',
),
DailyTask(
    level: 20,
    taskNumber: 13,
    totalTasks: 15,
    content: 'Today, integrate feedback effectively and adjust your communication dynamically.',
),
DailyTask(
    level: 20,
    taskNumber: 14,
    totalTasks: 15,
    content: 'Today, practice connecting ideas with storytelling, examples, and clear transitions.',
),
DailyTask(
    level: 20,
    taskNumber: 15,
    totalTasks: 15,
    content: 'Today, reflect on your communication journey, celebrate progress, and plan for continued mastery.',
),
];
