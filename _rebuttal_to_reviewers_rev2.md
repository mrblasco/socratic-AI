---
title: |
  AI Chatbots in K-12 Education
subtitle: Point-by-Point Rebuttal to Reviewer Comments - Second Round
geometry: margin=2.5cm
mainfont: Arial
toc: false
bibliography: [refs.bib]
header-includes: |
  ```{=latex}
  \usepackage{setspace}
  \doublespacing
  \usepackage{soul}
  ```
---

Dear Editor and Reviewers,

We thank the first two reviewers for approving the revisions to our manuscript and recommending it for publication in this journal. We also appreciate the opportunity to further revise and improve our work in this second round, following the insightful and constructive feedback provided by Reviewer #3. We sincerely thank Reviewer #3 for their thoughtful comments, which have helped us enhance the clarity and quality of the manuscript.

 Below, we provide a detailed point-by-point response. Reviewer comments are presented in **bold**, followed by our responses in regular text. Where applicable, we indicate changes made to the manuscript by referencing specific sections or page numbers.

--- 


# Reviewer 1

**Thanks for the revisions. My comments have been tackled very well and I can thus recommend publication.**

# Reviewer 2

**I like reading this paper. This paper makes a valuable and timely contribution to the field of AI in education, particularly in the underexplored K-12 context. The experimental design is sound, the findings are well-analyzed, and the implications are meaningful.**

# Reviewer 3

**The present paper aims to investigate how large language models can enhance the learning processes by providing learners with various forms of assistance. In two experiments the authors tasked students with solving school-related problems, providing different types of AI assistance to help them find solutions. In the first experiment, the AI provided or did not provide explanations for the generated student solutions. In the second experiment, the AI either applied a Socratic method when interacting with students or offered the solution directly. The results showed that providing explanations for AI-generated solutions is beneficial for learning, as opposed to not providing any explanations. Additionally, the authors found that although Socratic dialogue fostered engagement and interaction with AI, it did not improve learning or the perceived helpfulness of AI.**

**The topic that authors address in their article is likely of high relevance to the research community and, as authors state in their manuscript, is in need of comprehensive empirical investigation. Moreover, I appreciate the authors’ efforts in conducting a controlled field study with high school students, as such studies require substantial organizational effort. I also found it valuable that the authors used various tasks and combined quantitative and qualitative approaches in their experiments, although the results of the latter are not reported in the paper.**

**Unfortunately, despite the aforementioned strengths and the authors’ efforts, which I appreciate, I believe that the paper is inherently limited by its experimental methods and study design, which leads me to believe that revising the paper with data from the experiments would not be productive. For this reason, I regret to suggest rejecting this manuscript. Below, I will outline the study’s main limitations, which illustrate my main concerns and justify my decision.**

## Methodological concerns

**First and foremost, I was quite surprised to find that this paper in fact describes two unrelated experiments rather than one as the title and the abstract suggest (see section 2.4: It is important to note that these were conducted as independent experiments, with different dependent and independent variables, rather than a factorial 2x2 design). In my opinion, the use of AI is not a sufficient reason to combine the two experiments into a single “study” and into a single manuscript, especially since the authors do not contrast the theoretical concepts underlying the two experiments or their own empirical results. This makes me wonder whether it is reasonable to present the results of these two experiments in one paper. I believe the manuscript would benefit from a more focused approach: the authors should provide a thorough theoretical background on explanations or Socratic method and incorporate the results of the group discussions more specifically.**

We thank the reviewer for the opportunity to clarify this important point. We respectfully disagree that the experiments are “unrelated.” Both experiments investigate how AI assistance can enhance student learning, with a shared focus on the mechanisms of interaction. Specifically, Experiment 1 tests whether providing explanations improves learning outcomes, while Experiment 2 builds on that by asking how these explanations should be delivered — either through direct instruction or Socratic prompting. We agree that this distinction was not sufficiently emphasized in the earlier version of the manuscript and have now revised the title, introduction and discussion sections to clarify the theoretical connection and progression between the two studies. We believe presenting them together provides a richer understanding of the broader research question. 

**Unfortunately, the selected task (‘guessing the total value of the coins in a jar’) does not seem well-suited for investigating learning effects and does not correspond to a typical ‘school-related’ learning task. The phrase ‘you must guess’ in the instruction may cause young learners to view the task as one that should be solved based on mere intuition rather than geometric calculations.**

We respectfully disagree with the reviewer’s assessment that the estimation task is not well-suited for investigating learning effects and is not school-related. On the contrary, the task belongs to a class of open-ended estimation problems, often referred to as "Fermi problems," which are widely recognized and applied in both educational practice and research.Indeed, a growing literature supports the pedagogical value of Fermi problems. In a recent literature review on the use of Fermi Problems in STEM, @arleback2019use conclude that these tasks "enable students to tackle complex situations and content in all disciplines." @abay2020using document their use to engage students as early as 4th grade, emphasizing motivational benefits. Similarly, @micklo1999estimation describes classroom applications of estimation activities involving marbles, closely resembling our own task, as a way to develop students' numerical reasoning. In addition, pedagogical networks, such as EU Math Excellence for Upper Secondary Education, recommend the use of Fermi problems to improve students’ mathematical reasoning and problem-solving skills^[See: https://excellenceinmath.eu].

Morevero, these tasks are not limited to classroom use. They are also commonly used as research tools.  For example, @ferrando2021students reports a study that explores problem-solving skills of 8-16 years old students estimating how many people that can fit in their school playground; a task conceptually similar to estimating the value of coins in a jar. Similarly, Richard Thaler has used similar estimation exercises to illustrate phenomena such as the winner’s curse [@thaler1988anomalies]. 

We now clarify this aspect in the revision by citing this literature explicitly [p. xxx]. 

That said, we acknowledge the reviewer’s concern about the possible influence of the phrase “you must guess.” We have now added a footnote in the discussion section, clarifying that while the task involves estimation, it requires structured reasoning and not mere intuition. We report the footnote (p. xxx) here:

> "Although this task involves estimation (participants are expected to apply logical reasoning and draw on relevant knowledge, rather than rely solely on intuition), we acknowledge that the instruction to 'guess' might have unintentionally suggested that reasoning was not required. While we believe this interpretation is unlikely, if some participants did perceive the task this way, it could represent a potential confounding factor in performance."

**I also wonder how effectively Socratic dialogues can be analyzed using a simple yes-or-no question, such as, ‘Does sound travel faster in water than in air?’ In my opinion, an argumentative-essay-writing task, which the authors also used, is much more suitable. However, the authors did not report any results regarding this task.**

We thank the reviewer for raising the important point regarding the use of multiple-choice questions to evaluate the impact of Socratic AI. We agree that deeper, more complex assessments could provide additional insights. However, we would like to clarify that our evaluation does not rely on binary “yes/no” questions. For instance, the example cited by the reviewer (“Does sound travel faster in water than air? And if so, why?”) is part of a multiple-choice question with five distinct response options. These options represent different conceptual relationships between density and the speed of sound, for example, slower in water due to higher density, or faster in water due to higher density (see Questionnaire at the end of the paper).

To further assess conceptual understanding, students were asked to answer follow-up questions such as identifying which materials allow sound to travel faster. More broadly, our evaluation of Socratic AI does not depend solely on such factual questions, as implied. Rather, it incorporates multiple dimensions, including:

1. Factual multiple-choice questions to test conceptual understanding,
2. A 5-point Likert scale assessing students' perceived helpfulness of the AI, and
3. A 5-point Likert scale evaluating students’ confidence in completing related tasks.

We agree that open-ended responses can provide richer insights into students’ reasoning and their interactions with the AI. We appreciate the reviewer’s suggestion to analyze the students’ short essays for this purpose. However, conducting meaningful text analysis poses its own methodological challenges and would require defining appropriate measures of learning based on qualitative data; an important but complex task that falls outside the scope of the present study. Therefore, while this paper focuses on structured assessments, a separate analysis of students’ essay responses would be a valuable direction for future research, particularly for exploring how Socratic AI influences writing, reflection, and deeper cognitive engagement. 

**In the experiment investigating the effects of Socratic dialogues, measuring learners’ engagement based on the number of messages or words exchanged between them and the chatbot does not seem to be valid, because the observed results are primarily caused by the nature of the experimental instructions: if the chatbot asks learners questions in one condition but only provides answers in another, learners will naturally write more messages in the former.**

We agree that engagement metrics like message count or word count can be influenced by the structure of the dialogue and experimental conditions. However, we argue that these measures still offer a meaningful (if indirect) index of behavioral engagement — particularly in contrasting passive receipt of information versus active participation. To provide transparency, we have added a more detailed discussion of this limitation and included example dialogues in the appendix to illustrate the qualitative differences between conditions.

**Blurred focus of the study and insufficient theoretical background**

**The paper examines two well-researched areas related to learning: explanations and Socratic dialogue. However, neither topic is covered in sufficient detail. Instead, the chapter on the theoretical background merely provides a general overview of AI in education. While such an overview could form a good basis of an introduction, it is, unfortunately, too superficial to serve as a theoretical foundation. For example, it would be important to discuss what constitutes a good explanation, and the differences between human- and AI-generated explanations. Why might their impact on learning differ?**

> ?

**Presentation of the results**
**I found that the authors' presentation of their study’s results does not adhere to established standards for reporting empirical data. Furthermore, I would also advise against statements such as ‘We didn't have enough observations to reach a statistically significant association (Fisher's test, p = .27)’ since the lack of significance cannot and should not be primarily attributed to the sample size.**

We thank the reviewer for this comment and have revised the sentence changing it into "‘We didn't reach a statistically significant association (Fisher's test, p = .27)". 

\newpage 

# References