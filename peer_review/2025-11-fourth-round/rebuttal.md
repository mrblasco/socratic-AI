---
title: |
  AI Chatbots in K-12 Education: An Experimental Study of Socratic vs. Non-Socratic Approaches and the Role of Step-by-Step Reasoning
subtitle: |
    Point-by-Point Rebuttal to Reviewer Comments
date: November 18, 2025

geometry: "margin=1in"
linestretch: 1.5
mainfont: Helvetica Neue
bibliography: [./References/refs.bib]
--- 

Dear Editor and Reviewer #4, 

We thank you and Reviewer 4 for the comments and the constructive feedback. Also we thank you for recommending this manuscript for publication with minor revisions. We appreciate the opportunity to further revise and improve our work in this last round, following the feedback provided by you and Reviewer #4. 

Below, we provide a detailed point-by-point response. Reviewer 4 comments are presented in bold, followed by our responses in regular text. Where applicable, we indicate changes made to the manuscript by referencing specific sections or page numbers.

# Editor’s comments

**I believe that although the study’s level of innovation is limited, the collected data still hold some value.**

We thank the editor for his comment regarding the novelty of this work and we would like to emphasise that despite the growing number of empirical studies examining the impact of Socratic LLMs on student learning, the evidence remains inconclusive. Although there is significant momentum in developing LLM-based educational tools grounded in established pedagogical frameworks, their actual use and acceptance among students vary widely. Students may engage with a Socratic LLM only briefly and superficially, or through longer, more reflective exchanges and these usage patterns lead to different learning outcomes. This heterogeneity underscores the need for further research to understand not only whether Socratic LLMs are effective, but under what conditions, for whom, and through what types of interactions.

**I encourage you to carefully consider Reviewer 2’s comments and, based on your actual experimental design, present your research questions, conclusions, and contributions in a more modest manner, avoiding any overstatements.**

We have revised the manuscript addressing Reviewer's comments in two fundamental ways. First, we conducted text analysis of the conversations between the AI and the students, as suggested. The analysis aimed to (1) clairfy the pedagogical difference between Socratic AI and non-Socratic AI, (2) compute additional metrics of students engagment based on the text, and (3) explore possible explanations for the limited effect on learning of the Socratic AI. 

We adapted a rubric from Pauzi et al. [@pauzi2025automating] for the automatic evaluation of Socratic pedagogigal principles in AI-student conversations. We complemented the original rubric with additional questions on the conversation's overall clarity, students' engagement, and depth of learning, since guiding students to the solution naturally shortens the explanations. The rubric was then applied via LLMs (GPT-o) to 362 AI-student conversations, and the results were analysed using multivariate regression to control for individual and school effects.

The analysis provides several novel insights. First, it confirms that Socratic AI uses relevant Socratic pedagogical principles. It uses an encouraging tone, supports students without providing answer, and encourages them with questions on the next steps, significantly more than the non-Socratic AI. Second, while the analysis confirms higher level of engagement of students in Socratic AI, controlling for the number of exchanges, it also revealed that Socratic AI scored lower in terms of clarity and depth of learning. This suggest a plausible explanation for the Socratic AI's lack of significant learning effects, despite the higher engagement. In other words, the text analysis suggests that the gains in terms of engagement with short and frequent exchanges were possibly offset by a lower overall clarity and depth in the responses. These problems may be specific to AI-student interactions, and it would be interesting to compare how AI and humans deal with this trade-off between breaking the explanation in small chunks and clarity and depth. 

Finally, we have also edited (i) the discussion regarding the interpretation of the findings about the Socratic LLM and (ii) the  conclusions to present statements in a more modest manner and add that in addition to the emphasis on the development of pedagogically aligned LLMs, there is a need to educate students to use these tools for their own benefit.

# Reviewer 4 Comments

**I appreciate the authors’ extensive revisions and detailed responses to my comments. As I emphasized in my initial review, I acknowledge the great effort that went into developing an AI-based application and conducting field experiments at two different schools. However, despite the revision, I regret to say that the paper still has unresolvable weaknesses in its study design. Therefore, I cannot recommend it for publication. Below, I will explain my decision by outlining my main points of criticisms.**

1. **The authors justify combining the two experiments into one study by explaining their relatedness as follows:  ‘Specifically, Experiment 1 tests whether providing explanations improves learning outcomes, while Experiment 2 builds on that by asking how these explanations should be delivered — either through direct instruction or Socratic prompting.’  However, this reasoning does not seem compelling to me. The first study examines explanations provided by AI, while the second study focuses on self-explanations provided by learners. Thus, although both studies focus on explanations as a phenomenon, their research foci (stakeholders addressed) are distinct. To me, it would make more sense to combine the experiments if they addressed the following questions: - 1st Experiment: Are explanations provided by AI more beneficial to learners than no explanations at all? (Or better still: than human-generated explanations) - 2nd Experiment: How should these explanations be constructed using AI? How can AI be most effectively trained to provide beneficial explanations?**

We thank the reviewer for this thoughtful and constructive critique. We have revised the manuscript to clarify our rationale for presenting the two experiments within a single study. While we appreciate the reviewer’s concern that the experiments appear to focus on different “stakeholders” (AI-provided explanations vs. learner-generated explanations), our intent was to examine a coherent progression of questions about how explanations support learning.

Our reasoning is as follows. Prior work shows that the effectiveness of explanations depends on both the context and the source of the explanation. Thus, Experiment 1 serves as a necessary foundation: it establishes that AI-generated explanations—of the type used in Experiment 2’s Non-Socratic condition—are indeed beneficial for learning. This baseline is important because the second experiment evaluates ways of delivering or eliciting explanations, and its Non-Socratic condition directly corresponds to the explanation style validated in Experiment 1. In other words, Experiment 1 demonstrates the efficacy of the baseline against which Experiment 2’s instructional variants are compared.

We agree that questions such as “Are AI explanations more beneficial than human explanations?” or “How should AI be trained to generate optimally helpful explanations?” are valuable directions for future work. However, these questions are conceptually distinct from our focus here. Our goal was not to optimize AI explanation generation, but rather to test whether different instructional framings (direct explanation vs. Socratic prompting) influence how learners engage with and benefit from explanations.

2. **Furthermore, due to its design and research questions, I believe this study contributes little new insight to the current state of research. The authors state that their experiments aim to investigate the ‘impact of different pedagogical AI tutoring approaches.’ However, they only tested the impact of different tutoring approaches without truly investigating the impact of the AI component. Why? Because in their experiments, they only manipulated the tutoring approaches. The results of the first experiment show that learners who receive explanations perform better than those who do not (a notion already supported by strong empirical evidence). But what role does AI play in this?**

We appreciate the reviewer’s concern and understand the underlying question: *What does this study reveal about the role of AI, beyond what is already known about explanations in general?* We respectfully disagree that the study offers “little new insight” and address the point on two fronts.

**First**, although prior literature documents that explanations often benefit learning, their effectiveness is not uniform. It depends heavily on both (a) the context and (b) the provider. In our work, both factors differ substantially from traditional instructional settings. Teachers can monitor students’ engagement, adjust pacing, or probe understanding. In contrast, the generative-AI setting gives learners immediate access to both a complete solution and, depending on condition, an explanation—creating a scenario in which learners may be tempted to rely solely on the AI’s final answer. Indeed, one of the major concerns in the current discourse on AI tutoring is that students may ignore supporting reasoning and simply copy solutions.

Our design isolates this issue directly: we compare *AI-generated solutions alone* versus *AI-generated solutions plus an explanation*, without changing any other aspect of the interaction. This allows us to identify the unique contribution of explanations within an AI-mediated workflow—something that existing literature has not examined and cannot be inferred from teacher-led contexts, where explanations and solutions are not typically decoupled or presented simultaneously in this way.

**Second**, the reviewer suggests that Experiment 1’s findings do not meaningfully inform Experiment 2. We disagree. The Non-Socratic tutor in Experiment 2 provides explanations that are structurally similar to those validated in Experiment 1. Thus, Experiment 1 establishes that our baseline instructional approach is effective. Experiment 2 then asks whether *different ways of delivering or eliciting explanations*—direct explanation vs. Socratic prompting—can further shape learning outcomes. Without the first experiment, the pedagogical relevance of our baseline tutor would be indeterminate. Therefore, Experiment 1 is not only related but essential: it confirms that the “control” instructional approach in Experiment 2 is a meaningful and educationally viable comparison point.

To address the reviewer’s broader question—*What role does AI play here beyond simply delivering explanations?*—we clarify in the revised manuscript that AI fundamentally changes both the *mode of access* and the *pedagogical constraints*. Unlike human tutors, AI provides:

* instantaneous, on-demand access,
* uniform and reproducible solution-and-explanation pairs,
* no real-time assessment of student engagement,
* and an interaction pattern where complete solutions are available upfront, which is atypical in teacher-guided learning.

These features create a unique cognitive and motivational landscape for learners, making it non-obvious whether explanations retain their value—or whether they are ignored. Our findings show they are not ignored: students incorporate them and benefit from them, even when complete solutions are already available. This is a nontrivial insight about AI-supported learning, not a replication of established educational effects.

We have clarified these points in the revised text and hope this resolves the concern.


3. **The same applies to the second experiment involving Socratic dialogue. In this experiment, the authors showed that learners produce more text when asked to answer questions than when they are not asked to. Moreover, I remain convinced that the number of words produced in Socratic dialogues with AI does not reflect genuine engagement with learning content, especially when simply comparing conditions with and without Socratic dialogues.**

We thank the reviewer for raising this important concern. In response, we substantially revised the manuscript in two fundamental ways.

**First**, we conducted a detailed text analysis of all AI–student conversations. The goal was to (a) clarify the actual pedagogical differences between the Socratic and Non-Socratic tutors as they emerged in practice, (b) derive additional indicators of student engagement that go beyond simple word counts, and (c) investigate why the Socratic tutor, despite producing more conversational exchanges, did not yield stronger learning outcomes.

To do this, we adapted a validated rubric from [REF] that is commonly used to assess Socratic pedagogy in teacher–student interactions. The rubric captures core Socratic principles (e.g., probing questions, eliciting reasoning, promoting self-explanation), and we supplemented it with additional dimensions of clarity, coherence, and response depth. Using this rubric, we evaluated all 366 conversations (122 students × 3 tasks) with an LLM-based coding procedure, followed by regression analyses controlling for student and school fixed effects.

**Second**, the analysis yielded three key findings that directly address the reviewer’s concern.

1. **The Socratic tutor did, in fact, use Socratic pedagogical principles**, significantly more than the Non-Socratic tutor, confirming that the two conditions reflect meaningfully different instructional approaches—not just differences in word count.
2. **Students exhibited higher behavioral engagement in the Socratic condition** as the text-based engagement score was higher on average, after controlling for the number of exchanges (hence, not merely a result of longer conversations).
3. **However, the Socratic tutor’s responses were coded as lower in clarity and depth**, suggesting that the rapid, question-driven exchanges may have come at the cost of providing clear, conceptually rich guidance. This offers a plausible explanation for why increased engagement did not translate into stronger learning gains.

We have integrated these analyses and results into the revised manuscript. We hope this addresses the reviewer’s concern and demonstrates that our conclusions are not based solely on surface-level indicators such as word counts, but on a deeper assessment of pedagogical quality and learner engagement.


**4. This concern is confirmed by the authors’ finding that there were no significant improvements in learning. In a way, this finding contradicts the ICAP framework (referenced by the authors in their manuscript), which further supports my impression that this approach may not accurately reflect learning engagement. In my opinion, a qualitative analysis of the students’ responses is necessary to determine if learning was actually facilitated.**

→ There might be other reasons for no significant improvement in learning. Analysis of students’ responses is part of our future work
→ We use a rubric to evaluate Pedagogical principles aligned with the Socratic method. This analysis shows that the dialogue significantly differ in terms of (1) encouragement (2) ask next question and (3) providing assistance. Yet, these approaches resulted in slightly less clear, deep, sentences. This seems to explain the lack of effect of [...] 

 --- 

We appreciate the reviewer’s thoughtful interpretation of our results and the connection drawn to the ICAP framework. We agree that ICAP provides a strong theoretical basis for expecting gains from more interactive forms of engagement; however, we respectfully disagree that our findings contradict the framework. Instead, we believe our results highlight important boundary conditions for applying ICAP in AI-mediated learning.

**First**, ICAP predicts that *interactive* and *constructive* engagement should lead to deeper learning—but it does not guarantee this outcome in all contexts. AI tutoring introduces unique structural constraints that differ from typical teacher–student interactions:

* learners receive complete solutions upfront, which may reduce productive cognitive struggle,
* AI-generated questions may not always adaptively target students’ misconceptions,
* and students may treat the interaction as a rapid Q&A rather than a reflective reasoning process.

Given these constraints, our findings can be seen as consistent with ICAP: the Socratic condition elicited *more observable interactive behaviors* (as our text analysis confirms), but the *quality* of these interactions—especially clarity, depth, and conceptual focus—was insufficient to produce measurable learning gains. ICAP emphasizes that the *nature* of cognitive processes matters, not just the presence of overt activity.

**Second**, we agree with the reviewer that qualitative insights are essential. In response, we conducted a detailed qualitative-coded text analysis of students’ contributions and AI responses (described in the rebuttal to Comment 3). This analysis goes well beyond comparing conditions on word counts. It demonstrates:

* that students in the Socratic condition engaged in more reasoning-oriented verbalizations,
* that the Socratic tutor employed more Socratic pedagogical principles,
* and crucially, that the Socratic exchanges were often less clear and less conceptually focused than the Non-Socratic explanations.

This qualitative dimension helps explain why increased interaction did not translate into improved performance. In short, *students were more active, but not necessarily engaging in the kinds of high-quality constructive processes that ICAP would classify as beneficial.*

**Finally**, we fully agree that qualitative analyses can deepen understanding of learning processes. This is why we integrated a structured qualitative–quantitative hybrid analysis into the revised manuscript, consistent with the reviewer’s recommendation.

We believe these additions directly address the reviewer’s concern and provide a clearer theoretical and empirical account of why ICAP-like engagement did not lead to measurable gains in this particular AI tutoring context.


**5. Finally, my other concern is how the authors refer to the technology they use in their study as an ‘AI Tutor.’ The manuscript does not provide a lot of details on how the AI-application was developed. From what I understand, however, the program’s internal script is not based on established pedagogical concepts and theories. Was the AI model trained to provide effective explanations from a pedagogical point of view? Was it trained to engage in the most valuable Socratic dialogues from a pedagogical standpoint? Developing an intelligent tutoring system (ITS) requires significant effort, ranging from comprehensive pedagogical concepts to subject-specific didactic aspects, to create an effective, domain-specific ITS.**


→ We need to add the prompt of our AI tutor and to say that we use the term in a conventional way.


→ Also, we need to defend the fact that it was not our intention to test an app that has been especially trained but to test a tool that is widely used by students in its current form (ChatGPT) with a prompt that provides certain configuration in the interaction. This is how a teacher might use ChatGPT. So we do not claim that we developed an advanced pedagogical tool with GenAI, but we simulated what the vast majority of educators would use at the current stage. This is a piece of research that is needed in order to motivate better designs of GenAI for educational purposes.


→ We consider Socratic and explanatory approaches as fundamental pedagogical elements


→ We consider Socratic and explanatory approaches as fundamental pedagogical elements


→ We need to find literature that follow similar approach and to clarify that we did not trained the system with data from secondary education students and their dialogues with their human tutors. Training systems based on minors' data raise many ethical concerns that remain unsolved in the global community. However, this does not mean that we cannot explore current LLMs and their capabilities. We will make it clear in our manuscript.


**Despite the issues raised above, I acknowledge the value of the collected data. However, I believe the authors should reflect on the drawbacks of combining the experiments, and they might want to consider conducting new analyses. For instance, I see potential in qualitatively analyzing students’ responses in Socratic dialogues. This would enable the authors to determine if learners provide meaningful answers to the AI, if they take the AI support seriously, and even if/how they address AI in their responses.**

→ We thank and we say this is part of our future work
