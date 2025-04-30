-- BattleState.lua

BattleState = {}
BattleState.__index = BattleState

function BattleState:new(party, enemies)
  local self = setmetatable({}, BattleState)
  self.party = party
  self.enemies = enemies
  self.turnOrder = {}
  self.currentTurnIndex = 1
  self.currentActor = nil
  self.uiPhase = "action"
  self.selectedAction = nil
  self.selectedSkill = nil
  self.selectedTarget = nil
  self:calculateTurnOrder()
  return self
end

function BattleState:calculateTurnOrder()
  self.turnOrder = {}
  for _, actor in pairs(self.party) do
    table.insert(self.turnOrder, actor)
  end
  for _, enemy in ipairs(self.enemies) do
    table.insert(self.turnOrder, enemy)
  end
  table.sort(self.turnOrder, function(a, b) return a.speed > b.speed end)
  self.currentActor = self.turnOrder[self.currentTurnIndex]
end

function BattleState:nextTurn()
  self.currentTurnIndex = self.currentTurnIndex + 1
  if self.currentTurnIndex > #self.turnOrder then
    self.currentTurnIndex = 1
    self:calculateTurnOrder() -- refresh in case of KO
  end
  self.currentActor = self.turnOrder[self.currentTurnIndex]
  self.uiPhase = "action"
  self.selectedAction = nil
  self.selectedSkill = nil
  self.selectedTarget = nil
end

function BattleState:update(dt)
  -- Enemy auto moves can go here
end

function BattleState:draw()
  self:drawHUD()
  self:drawBattleUI()
end

function BattleState:drawHUD()
  local x = 400
  for _, char in pairs(self.party) do
    ui.label(char.name, x, 400)
    ui.label("HP: " .. char.hp .. "/" .. char.maxHp, x, 420)
    ui.label("Emotion: " .. char.emotion, x, 440)
    x = x + 150
  end
end

function BattleState:drawBattleUI()
  if self.currentActor and self.currentActor.isPlayer then
    ui.label("What will " .. self.currentActor.name .. " do?", 50, 400)

    if self.uiPhase == "action" then
      if ui.button("Attack", 50, 430) then
        self.selectedAction = "attack"
        self.uiPhase = "target"
      end
      if ui.button("Skill", 50, 460) then
        self.uiPhase = "skills"
      end
      if ui.button("Guard", 50, 490) then
        self.selectedAction = "guard"
        self.uiPhase = "resolve"
      end
    elseif self.uiPhase == "skills" then
      for i, skillName in ipairs(self.currentActor.skills) do
        local skill = Skills[skillName]
        if ui.button(skill.name, 50, 430 + i * 30) then
          self.selectedSkill = skill
          self.selectedAction = "skill"
          self.uiPhase = "target"
        end
      end
    elseif self.uiPhase == "target" then
      for i, enemy in ipairs(self.enemies) do
        if ui.button(enemy.name .. " (HP: " .. enemy.hp .. ")", 200, 430 + i * 30) then
          self.selectedTarget = enemy
          self.uiPhase = "resolve"
        end
      end
    end
  end

  if self.uiPhase == "resolve" then
    if self.selectedAction == "attack" then
      Skills["stab"].effect(self.currentActor, self.selectedTarget)
    elseif self.selectedAction == "skill" and self.selectedSkill then
      if self.selectedSkill.name == "Rebound" or self.selectedSkill.name == "Snack Time" then
        self.selectedSkill.effect(self.currentActor, self.enemies)
      else
        self.selectedSkill.effect(self.currentActor, self.selectedTarget)
      end
    elseif self.selectedAction == "guard" then
      Skills["guard"].effect(self.currentActor)
    end

    self:nextTurn()
  end
end

-- EMOTION SYSTEM ----------------------

emotions = {
    neutral = function(stats) return stats end,
    happy = function(stats)
        stats.luck = stats.luck + 5
        stats.speed = stats.speed + 2
        stats.accuracy = stats.accuracy - 10
        return stats
    end,
    angry = function(stats)
        stats.attack = stats.attack + 5
        stats.defense = stats.defense - 3
        return stats
    end,
    sad = function(stats)
        stats.defense = stats.defense + 5
        stats.speed = stats.speed - 2
        return stats
    end
}

emotionTriangle = {
    happy = { beats = "angry", loses = "sad" },
    angry = { beats = "sad", loses = "happy" },
    sad   = { beats = "happy", loses = "angry" },
    neutral = { beats = nil, loses = nil }
}

function getEmotionModifier(attackerEmotion, defenderEmotion)
    if emotionTriangle[attackerEmotion].beats == defenderEmotion then
        return 1.2
    elseif emotionTriangle[attackerEmotion].loses == defenderEmotion then
        return 0.8
    else
        return 1.0
    end
end

-- CHARACTERS & SKILLS -----------------

function createCharacter(name, hp, mp, attack, defense, speed, emotion)
    return {
        name = name,
        hp = hp,
        mp = mp,
        base = {attack = attack, defense = defense, speed = speed, luck = 0, accuracy = 100},
        emotion = emotion or "neutral",
        isEnemy = false,
        skills = {}
    }
end

function getEffectiveStats(char)
    local stats = {
        attack = char.base.attack,
        defense = char.base.defense,
        speed = char.base.speed,
        luck = char.base.luck,
        accuracy = char.base.accuracy
    }

    return emotions[char.emotion](stats)
end

function createSkill(name, cost, effectFunc, changeEmotion)
    return {
        name = name,
        cost = cost,
        effect = effectFunc,
        emotionChange = changeEmotion
    }
end

-- SKILLS ------------------------------

basicSkills = {
    createSkill("Mock", 10, function(user, target)
        local dmg = math.max(getEffectiveStats(user).attack - getEffectiveStats(target).defense, 2)
        dmg = math.floor(dmg * getEmotionModifier(user.emotion, target.emotion))
        target.hp = math.max(target.hp - dmg, 0)
        print(user.name .. " mocks " .. target.name .. " for " .. dmg .. " damage!")
    end, "sad"),

    createSkill("Rage Hit", 15, function(user, target)
        local dmg = getEffectiveStats(user).attack + 5
        dmg = math.floor(dmg * getEmotionModifier(user.emotion, target.emotion))
        target.hp = math.max(target.hp - dmg, 0)
        print(user.name .. " unleashes rage on " .. target.name .. " for " .. dmg .. " damage!")
    end, "angry"),

    createSkill("Cheer Up", 10, function(user, target)
        print(user.name .. " cheers up " .. target.name)
    end, "happy")
}

-- PARTY & ENEMIES ---------------------

party = {
    createCharacter("Omori", 100, 50, 10, 5, 10, "neutral"),
    createCharacter("Aubrey", 120, 40, 15, 8, 6, "angry"),
    createCharacter("Kel", 90, 50, 8, 4, 12, "happy")
}

enemies = {
    createCharacter("Lost Sprout Mole", 60, 0, 7, 3, 5, "sad"),
    createCharacter("Big Strong Mole", 100, 0, 12, 6, 4, "angry")
}

-- Assign enemy flags
for _, e in ipairs(enemies) do e.isEnemy = true end

-- Assign skills
party[1].skills = { basicSkills[1], basicSkills[3] }
party[2].skills = { basicSkills[2] }
party[3].skills = { basicSkills[3] }

-- ACTIONS -----------------------------

function isAlive(char) return char.hp > 0 end

function attack(attacker, target)
    local atkStats = getEffectiveStats(attacker)
    local defStats = getEffectiveStats(target)

    local dmg = math.max(atkStats.attack - defStats.defense, 1)
    dmg = math.floor(dmg * getEmotionModifier(attacker.emotion, target.emotion))
    target.hp = math.max(target.hp - dmg, 0)

    print(attacker.name .. " attacks " .. target.name .. " for " .. dmg .. " damage! (" .. target.hp .. " HP left)")
end

function changeEmotion(target, newEmotion)
    target.emotion = newEmotion
    print(target.name .. " is now " .. newEmotion .. "!")
end

function selectTarget(fromList)
    for i, target in ipairs(fromList) do
        print(i .. ". " .. target.name .. " (" .. target.emotion .. ", " .. target.hp .. " HP)")
    end
    io.write("Choose target: ")
    return fromList[tonumber(io.read())]
end

function useSkill(user)
    if #user.skills == 0 then print("No skills available!"); return end
    print("Available Skills:")
    for i, skill in ipairs(user.skills) do
        print(i .. ". " .. skill.name .. " (" .. skill.cost .. " juice)")
    end
    io.write("Choose skill: ")
    local skill = user.skills[tonumber(io.read())]

    if user.mp < skill.cost then
        print("Not enough juice!")
        return
    end

    local targets = user.isEnemy and party or enemies
    local aliveTargets = {}
    for _, t in ipairs(targets) do if isAlive(t) then table.insert(aliveTargets, t) end end
    local target = selectTarget(aliveTargets)

    user.mp = user.mp - skill.cost
    skill.effect(user, target)
    if skill.emotionChange then
        changeEmotion(target, skill.emotionChange)
    end
end

function playerTurn(player)
    print("\n" .. player.name .. "'s Turn! (" .. player.emotion .. ", " .. player.hp .. " HP, " .. player.mp .. " MP)")
    print("1. Attack")
    print("2. Use Skill")
    print("3. Change Own Emotion")
    io.write("Choose action: ")
    local action = tonumber(io.read())

    if action == 1 then
        local validTargets = {}
        for _, e in ipairs(enemies) do if isAlive(e) then table.insert(validTargets, e) end end
        local target = selectTarget(validTargets)
        attack(player, target)
    elseif action == 2 then
        useSkill(player)
    elseif action == 3 then
        print("Choose emotion: 1. Happy  2. Angry  3. Sad")
        local chosen = ({ "happy", "angry", "sad" })[tonumber(io.read())]
        changeEmotion(player, chosen)
    end
end

function enemyTurn(enemy)
    local validTargets = {}
    for _, p in ipairs(party) do if isAlive(p) then table.insert(validTargets, p) end end
    local target = validTargets[math.random(#validTargets)]
    attack(enemy, target)
end

function getAllCombatants()
    local all = {}
    for _, p in ipairs(party) do if isAlive(p) then table.insert(all, p) end end
    for _, e in ipairs(enemies) do if isAlive(e) then table.insert(all, e) end end
    table.sort(all, function(a, b)
        return getEffectiveStats(a).speed > getEffectiveStats(b).speed
    end)
    return all
end

function isBattleOver()
    local partyAlive, enemyAlive = false, false
    for _, p in ipairs(party) do if isAlive(p) then partyAlive = true end end
    for _, e in ipairs(enemies) do if isAlive(e) then enemyAlive = true end end
    return not (partyAlive and enemyAlive)
end

function printBattleStatus()
    print("\n--- Party ---")
    for _, p in ipairs(party) do print(p.name .. ": " .. p.hp .. " HP, " .. p.mp .. " MP [" .. p.emotion .. "]") end
    print("--- Enemies ---")
    for _, e in ipairs(enemies) do print(e.name .. ": " .. e.hp .. " HP [" .. e.emotion .. "]") end
end

-- BATTLE LOOP -------------------------

function battleLoop()
    while not isBattleOver() do
        printBattleStatus()
        local turnOrder = getAllCombatants()
        for _, char in ipairs(turnOrder) do
            if isAlive(char) then
                if not char.isEnemy then
                    playerTurn(char)
                else
                    enemyTurn(char)
                end
            end
        end
    end

    print("\n--- Battle Over ---")
    if isAlive(party[1]) then
        print("You win!")
    else
        print("You lose...")
    end
end

-- START BATTLE
math.randomseed(os.time())
battleLoop()
