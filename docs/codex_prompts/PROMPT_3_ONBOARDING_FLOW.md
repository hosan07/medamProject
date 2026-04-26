# PROMPT 3 — 회원가입 온보딩

Using master context, build the multi-step onboarding flow.

## State

Create a single onboarding state holder that stores:

- `nickname`
- `birthDate`
- `gender`
- `height`
- `goal`
- `goalReason`
- `triedBefore`
- `currentWeight`
- `targetWeight`
- `activityLevel`
- `waterIntake`
- `exerciseTypes`
- `aiCoach`
- `recommendedDiet`

## Flow

- Each step is a separate screen under `lib/features/onboarding/screens/`.
- Use go_router sub-routes: `/onboarding/:step`.
- Show progress at the top of each screen.
- Show `이전` on all steps except step 1.
- Show `다음` or `완료` at the bottom.
- Design responsively for phones and tablets without scaling font sizes by viewport width.

## Steps

1. `step1_nickname.dart`: nickname text field, 2~10 chars, Korean/English/numbers.
2. `step2_birthdate.dart`: year/month/day date picker.
3. `step3_gender.dart`: card selection, 남성 / 여성.
4. `step4_height.dart`: number picker, 140cm~220cm.
5. `step5_goal.dart`: single goal selection.
6. `step6_goal_reason.dart`: dynamic goal reason selection.
7. `step7_tried_before.dart`: previous attempt selection.
8. `step8_weight.dart`: current and target weight pickers.
9. `step9_activity.dart`: 5-level activity selector.
10. `step10_water.dart`: water intake selector.
11. `step11_exercise.dart`: multi-select exercise chips, with skip.
12. `step12_ai_coach.dart`: AI coach selection.
13. `step13_plan_loading.dart`: animated progress from 0 to 100%.
14. `step14_plan_result.dart`: input summary, BMR, TDEE, target calories.
15. `step15_diet_type.dart`: diet type selection.
16. `step16_complete.dart`: celebration, notification permission, save profile, route home.

## Save

Save onboarding data on completion to:

```text
users/{uid}/profile/main
```

Also mirror key profile fields on:

```text
users/{uid}
```
