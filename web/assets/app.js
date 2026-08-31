/*
 * Копилка — веб-демо.
 * Тот же продукт, что и в iOS-версии: цели, пополнения, прогресс и статистика.
 * Данные лежат в localStorage браузера и никуда не отправляются.
 */

(() => {
  "use strict";

  const STORAGE_KEY = "kopilka.state.v1";

  /** crypto.randomUUID есть не везде (например, при открытии файла с диска). */
  const uuid = () =>
    typeof crypto !== "undefined" && crypto.randomUUID
      ? crypto.randomUUID()
      : `id-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;

  const CURRENCIES = [
    { code: "RUB", symbol: "₽", title: "Российский рубль", quick: [500, 1000, 5000] },
    { code: "USD", symbol: "$", title: "Доллар США", quick: [10, 50, 100] },
    { code: "EUR", symbol: "€", title: "Евро", quick: [10, 50, 100] },
    { code: "KZT", symbol: "₸", title: "Тенге", quick: [500, 1000, 5000] },
    { code: "AED", symbol: "د.إ", title: "Дирхам ОАЭ", quick: [10, 50, 100] },
    { code: "GEL", symbol: "₾", title: "Лари", quick: [10, 50, 100] },
  ];

  const PALETTES = {
    gold: { title: "Золото", colors: ["#f9d689", "#d79a3f"] },
    sunset: { title: "Закат", colors: ["#ff9a76", "#e05c6e"] },
    ocean: { title: "Океан", colors: ["#76c8f0", "#3b6fd4"] },
    forest: { title: "Лес", colors: ["#8fd6a0", "#2e8b6b"] },
    orchid: { title: "Орхидея", colors: ["#c9a7f5", "#7a55c8"] },
    graphite: { title: "Графит", colors: ["#9aa3b2", "#3d4552"] },
  };

  const ICONS = [
    "🎯", "🏠", "🚗", "✈️", "🏝️", "🎓", "🎁", "❤️",
    "🎮", "💻", "📱", "📷", "🎧", "🚲", "🐾", "🩺",
    "☕️", "🍽️", "📚", "⛺️", "🎟️", "🛠️", "👜", "📦",
    "✨", "👑", "💍", "🏦", "📈", "🌱",
  ];

  const MONTHS_SHORT = ["янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"];

  // --- Состояние ---------------------------------------------------------

  const defaultState = () => ({
    goals: [],
    settings: { currency: "RUB", theme: "system" },
  });

  let state = defaultState();
  let activeTab = "goals";

  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return defaultState();
      const parsed = JSON.parse(raw);
      if (!parsed || !Array.isArray(parsed.goals)) return defaultState();
      return {
        goals: parsed.goals,
        settings: Object.assign(defaultState().settings, parsed.settings || {}),
      };
    } catch (error) {
      return defaultState();
    }
  }

  function save() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (error) {
      /* приватный режим — демо продолжает работать без сохранения */
    }
  }

  // --- Вычисления --------------------------------------------------------

  const round2 = (value) => Math.round((Number(value) || 0) * 100) / 100;

  const currency = () => CURRENCIES.find((item) => item.code === state.settings.currency) || CURRENCIES[0];

  function formatMoney(amount, options = {}) {
    const value = Number(amount) || 0;
    try {
      return new Intl.NumberFormat("ru-RU", {
        style: "currency",
        currency: currency().code,
        maximumFractionDigits: options.fraction ? 2 : 0,
        minimumFractionDigits: 0,
      }).format(value);
    } catch (error) {
      return `${Math.round(value)} ${currency().symbol}`;
    }
  }

  function compact(amount) {
    const value = Number(amount) || 0;
    if (Math.abs(value) >= 1e6) return `${(value / 1e6).toFixed(1).replace(".0", "").replace(".", ",")} млн`;
    if (Math.abs(value) >= 1000) return `${(value / 1000).toFixed(1).replace(".0", "").replace(".", ",")} тыс.`;
    return String(Math.round(value));
  }

  function plural(count, one, few, many) {
    const abs = Math.abs(count) % 100;
    const last = abs % 10;
    if (abs > 10 && abs < 20) return many;
    if (last === 1) return one;
    if (last >= 2 && last <= 4) return few;
    return many;
  }

  const saved = (goal) =>
    Math.max(
      0,
      round2(goal.transactions.reduce((sum, item) => sum + (item.kind === "deposit" ? item.amount : -item.amount), 0)),
    );

  const remaining = (goal) => Math.max(0, round2(goal.target - saved(goal)));
  const progress = (goal) => (goal.target > 0 ? Math.min(1, Math.max(0, saved(goal) / goal.target)) : 0);
  const isCompleted = (goal) => goal.target > 0 && saved(goal) >= goal.target;
  const palette = (goal) => PALETTES[goal.palette] || PALETTES.gold;
  const gradient = (goal) => `linear-gradient(135deg, ${palette(goal).colors[0]}, ${palette(goal).colors[1]})`;
  const accent = (goal) => palette(goal).colors[1];

  function daysLeft(goal) {
    if (!goal.deadline) return null;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const target = new Date(`${goal.deadline}T00:00:00`);
    return Math.round((target - today) / 86400000);
  }

  function deadlineText(goal) {
    const days = daysLeft(goal);
    if (days === null) return null;
    if (isCompleted(goal)) return "Цель закрыта";
    if (days < 0) return `Просрочено на ${Math.abs(days)} ${plural(Math.abs(days), "день", "дня", "дней")}`;
    if (days === 0) return "Последний день";
    return `Осталось ${days} ${plural(days, "день", "дня", "дней")}`;
  }

  function weeklyPace(goal) {
    const days = daysLeft(goal);
    if (days === null || days <= 0 || isCompleted(goal) || remaining(goal) <= 0) return null;
    return round2((remaining(goal) / days) * 7);
  }

  const allTransactions = () => state.goals.flatMap((goal) => goal.transactions);
  const totalSaved = () => round2(state.goals.reduce((sum, goal) => sum + saved(goal), 0));
  const totalTarget = () => round2(state.goals.reduce((sum, goal) => sum + goal.target, 0));

  function depositsThisMonth() {
    const now = new Date();
    return round2(
      allTransactions()
        .filter((item) => {
          if (item.kind !== "deposit") return false;
          const date = new Date(item.date);
          return date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth();
        })
        .reduce((sum, item) => sum + item.amount, 0),
    );
  }

  function weekStart(date) {
    const copy = new Date(date);
    copy.setHours(0, 0, 0, 0);
    const shift = (copy.getDay() + 6) % 7; // неделя начинается с понедельника
    copy.setDate(copy.getDate() - shift);
    return copy.getTime();
  }

  function weeklyStreak() {
    const weeks = new Set(
      allTransactions()
        .filter((item) => item.kind === "deposit")
        .map((item) => weekStart(new Date(item.date))),
    );
    if (!weeks.size) return 0;

    let cursor = weekStart(new Date());
    if (!weeks.has(cursor)) cursor -= 7 * 86400000;

    let streak = 0;
    while (weeks.has(cursor)) {
      streak += 1;
      cursor -= 7 * 86400000;
    }
    return streak;
  }

  function monthlyBuckets(count = 6) {
    const now = new Date();
    const buckets = [];
    for (let offset = count - 1; offset >= 0; offset -= 1) {
      const start = new Date(now.getFullYear(), now.getMonth() - offset, 1);
      const end = new Date(now.getFullYear(), now.getMonth() - offset + 1, 1);
      const deposits = allTransactions()
        .filter((item) => item.kind === "deposit")
        .filter((item) => {
          const date = new Date(item.date);
          return date >= start && date < end;
        })
        .reduce((sum, item) => sum + item.amount, 0);
      buckets.push({ label: MONTHS_SHORT[start.getMonth()], deposits: round2(deposits) });
    }
    return buckets;
  }

  // --- Утилиты рендера ---------------------------------------------------

  const escapeHtml = (value) =>
    String(value).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]);

  function ring(value, size, width, colors, centerHtml = "") {
    const radius = (size - width) / 2;
    const circumference = 2 * Math.PI * radius;
    const offset = circumference * (1 - Math.min(1, Math.max(0, value)));
    const id = `grad-${Math.random().toString(36).slice(2, 9)}`;
    return `
      <div class="ring-wrap" style="width:${size}px;height:${size}px">
        <svg class="ring" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" aria-hidden="true">
          <defs>
            <linearGradient id="${id}" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stop-color="${colors[0]}" />
              <stop offset="100%" stop-color="${colors[1]}" />
            </linearGradient>
          </defs>
          <circle class="track" cx="${size / 2}" cy="${size / 2}" r="${radius}" stroke-width="${width}" />
          <circle class="value" cx="${size / 2}" cy="${size / 2}" r="${radius}" stroke-width="${width}"
            stroke="url(#${id})" stroke-dasharray="${circumference}" stroke-dashoffset="${offset}" />
        </svg>
        <div class="ring-center">${centerHtml}</div>
      </div>`;
  }

  const percentText = (value) => `${Math.floor(value * 100)}%`;

  function goalCard(goal) {
    const chips = [];
    if (isCompleted(goal)) {
      chips.push(`<span class="chip" style="color:var(--positive);background:rgba(46,148,100,.14)">✓ Цель достигнута</span>`);
    } else if (deadlineText(goal)) {
      const overdue = (daysLeft(goal) ?? 0) < 0;
      chips.push(
        `<span class="chip" style="color:${overdue ? "var(--negative)" : "var(--text-2)"};background:${
          overdue ? "rgba(192,80,63,.14)" : "var(--surface-sunken)"
        }">${escapeHtml(deadlineText(goal))}</span>`,
      );
    } else if (weeklyPace(goal)) {
      chips.push(`<span class="chip" style="color:var(--text-2);background:var(--surface-sunken)">${formatMoney(weeklyPace(goal))} в неделю</span>`);
    }

    return `
      <div style="position:relative">
        <button class="card goal-card" data-action="open-goal" data-id="${goal.id}">
          <span class="goal-top">
            <span class="goal-badge" style="background:${gradient(goal)}">${goal.icon}</span>
            <span style="min-width:0;flex:1">
              <span class="goal-title">${escapeHtml(goal.title)}</span>
              ${chips.join("")}
            </span>
            <span style="width:38px;flex:none"></span>
          </span>
          <span>
            <span class="bar"><i style="width:${progress(goal) * 100}%;background:${gradient(goal)}"></i></span>
            <span class="goal-amounts">
              <span class="goal-saved">${formatMoney(saved(goal))}</span>
              <span class="goal-target">/ ${formatMoney(goal.target)}</span>
              <span class="goal-percent" style="color:${accent(goal)}">${percentText(progress(goal))}</span>
            </span>
          </span>
        </button>
        <button class="icon-btn goal-quick" data-action="quick-add" data-id="${goal.id}"
          style="color:${accent(goal)}" aria-label="Пополнить цель ${escapeHtml(goal.title)}">+</button>
      </div>`;
  }

  // --- Экраны ------------------------------------------------------------

  function renderGoals() {
    if (!state.goals.length) {
      return `
        <div class="card empty">
          <div class="empty-icon">✨</div>
          <h2>Здесь появятся ваши цели</h2>
          <p>Отпуск, техника, подушка безопасности — придумайте цель, назначьте сумму и откладывайте в своём темпе.</p>
          <div class="stack">
            <button class="btn btn-primary" data-action="new-goal">Создать первую цель</button>
            <button class="btn btn-secondary" data-action="load-demo">Посмотреть на примере</button>
          </div>
        </div>`;
    }

    const active = state.goals.filter((goal) => !isCompleted(goal));
    const done = state.goals.filter(isCompleted);
    const overall = totalTarget() > 0 ? Math.min(1, totalSaved() / totalTarget()) : 0;
    const streak = weeklyStreak();

    const section = (title, subtitle, goals) =>
      goals.length
        ? `<div class="section-head"><div><h2>${title}</h2><p>${subtitle}</p></div></div>
           ${goals.map(goalCard).join("")}`
        : "";

    return `
      <div class="card balance">
        <div class="balance-top">
          <div style="min-width:0">
            <div class="balance-label">Всего накоплено</div>
            <div class="balance-value">${formatMoney(totalSaved())}</div>
            <div class="balance-target">из ${formatMoney(totalTarget())}</div>
          </div>
          ${ring(overall, 76, 9, PALETTES.gold.colors, `<span class="ring-percent">${percentText(overall)}</span>`)}
        </div>
        <div class="metrics">
          <div class="metric">
            <span class="metric-dot" style="background:rgba(46,148,100,.14);color:var(--positive)">↓</span>
            <span style="min-width:0">
              <div class="metric-value">${depositsThisMonth() > 0 ? `+${formatMoney(depositsThisMonth())}` : "—"}</div>
              <div class="metric-title">В этом месяце</div>
            </span>
          </div>
          <div class="metric">
            <span class="metric-dot" style="background:var(--accent-soft);color:var(--accent)">🔥</span>
            <span style="min-width:0">
              <div class="metric-value">${streak > 0 ? `${streak} ${plural(streak, "неделя", "недели", "недель")}` : "—"}</div>
              <div class="metric-title">Недель подряд</div>
            </span>
          </div>
        </div>
      </div>

      ${section("Активные цели", `${active.length} ${plural(active.length, "цель", "цели", "целей")} в работе`, active)}
      ${section("Достигнуто", `${done.length} ${plural(done.length, "цель", "цели", "целей")} закрыто`, done)}

      <button class="btn btn-secondary" data-action="new-goal" style="width:100%">+ Новая цель</button>`;
  }

  function renderStats() {
    if (!allTransactions().length) {
      return `
        <div class="card empty">
          <div class="empty-icon">▨</div>
          <h2>Статистика появится позже</h2>
          <p>Сделайте первое пополнение — и здесь появятся динамика по месяцам, средний вклад и серия недель.</p>
          <div class="stack">
            <button class="btn btn-secondary" data-action="load-demo">Загрузить демо-данные</button>
          </div>
        </div>`;
    }

    const deposits = allTransactions().filter((item) => item.kind === "deposit");
    const average = deposits.length ? round2(deposits.reduce((sum, item) => sum + item.amount, 0) / deposits.length) : 0;
    const buckets = monthlyBuckets();
    const maxDeposit = Math.max(...buckets.map((bucket) => bucket.deposits), 1);
    const withMoney = state.goals.filter((goal) => saved(goal) > 0);

    const tile = (title, value, icon, color) => `
      <div class="card tile">
        <span class="tile-icon" style="background:${color}22;color:${color}">${icon}</span>
        <span class="tile-value">${value}</span>
        <span class="tile-title">${title}</span>
      </div>`;

    return `
      <div class="tiles">
        ${tile("Всего накоплено", formatMoney(totalSaved()), "💰", "#d79a3f")}
        ${tile("Пополнено в этом месяце", formatMoney(depositsThisMonth()), "📅", "#2e9464")}
        ${tile("Средний вклад", formatMoney(average), "📈", "#3b6fd4")}
        ${tile("Недель подряд с пополнением", String(weeklyStreak()), "🔥", "#e05c6e")}
        ${tile("Целей закрыто", String(state.goals.filter(isCompleted).length), "✅", "#2e8b6b")}
        ${tile("Всего пополнений", String(deposits.length), "↓", "#7a55c8")}
      </div>

      <div class="card">
        <div class="section-head"><div><h2>Последние 6 месяцев</h2><p>Пополнения по месяцам</p></div></div>
        <div class="chart">
          ${buckets
            .map(
              (bucket) => `
            <div class="chart-col">
              <span class="chart-cap">${bucket.deposits > 0 ? compact(bucket.deposits) : ""}</span>
              <div class="chart-bar" style="height:${Math.max((bucket.deposits / maxDeposit) * 100, bucket.deposits > 0 ? 4 : 2)}%;opacity:${
                bucket.deposits > 0 ? 1 : 0.15
              }"></div>
              <span class="chart-label">${bucket.label}</span>
            </div>`,
            )
            .join("")}
        </div>
      </div>

      ${
        withMoney.length
          ? `<div class="card">
              <div class="section-head"><div><h2>Распределение</h2><p>Где лежат накопления</p></div></div>
              ${withMoney
                .map((goal) => {
                  const share = totalSaved() > 0 ? saved(goal) / totalSaved() : 0;
                  return `
                    <div class="dist-row">
                      <div class="dist-top">
                        <span class="goal-badge" style="width:30px;height:30px;border-radius:10px;font-size:15px;background:${palette(goal).colors[1]}22">${goal.icon}</span>
                        <span>${escapeHtml(goal.title)}</span>
                        <span class="dist-share">${Math.round(share * 100)}%</span>
                      </div>
                      <span class="bar" style="height:6px"><i style="width:${share * 100}%;background:${gradient(goal)}"></i></span>
                    </div>`;
                })
                .join("")}
            </div>`
          : ""
      }`;
  }

  function renderSettings() {
    const themes = [
      { id: "system", title: "Как в системе", icon: "📱" },
      { id: "light", title: "Светлая", icon: "☀️" },
      { id: "dark", title: "Тёмная", icon: "🌙" },
    ];

    return `
      <div class="card">
        <div class="section-head"><div><h2>Оформление</h2></div></div>
        <div class="option-row options-3" style="margin-top:12px">
          ${themes
            .map(
              (theme) => `
            <button class="option ${state.settings.theme === theme.id ? "is-active" : ""}" data-action="set-theme" data-value="${theme.id}">
              <span class="option-symbol">${theme.icon}</span>${theme.title}
            </button>`,
            )
            .join("")}
        </div>
      </div>

      <div class="card">
        <div class="section-head"><div><h2>Валюта</h2><p>Меняет только отображение сумм</p></div></div>
        <div class="option-row options-6" style="margin-top:12px">
          ${CURRENCIES.map(
            (item) => `
            <button class="option ${state.settings.currency === item.code ? "is-active" : ""}" data-action="set-currency" data-value="${item.code}"
              title="${item.title}">
              <span class="option-symbol">${item.symbol}</span>${item.code}
            </button>`,
          ).join("")}
        </div>
      </div>

      <div class="card" style="display:flex;flex-direction:column;gap:12px">
        <button class="btn btn-secondary" data-action="load-demo">Загрузить демо-данные</button>
        <button class="btn btn-secondary" style="color:var(--negative)" data-action="reset">Удалить все данные</button>
      </div>

      <div class="card">
        <div class="section-head"><div><h2>О демо</h2></div></div>
        <p class="setting-note" style="margin-top:10px">
          Это веб-версия приложения «Копилка» для iOS. Данные хранятся только в вашем браузере
          (localStorage) и никуда не отправляются: ни аналитики, ни аккаунтов, ни серверов.
        </p>
        <p class="setting-note" style="margin-top:10px">
          <a class="link-row" href="/">← Вернуться на страницу приложения</a>
        </p>
      </div>`;
  }

  // --- Листы -------------------------------------------------------------

  const sheetRoot = () => document.getElementById("sheet-root");

  function openSheet(title, bodyHtml, options = {}) {
    sheetRoot().innerHTML = `
      <div class="sheet-backdrop" data-action="close-sheet-backdrop">
        <div class="sheet" role="dialog" aria-modal="true" aria-label="${escapeHtml(title)}">
          <div class="sheet-grabber"></div>
          <div class="sheet-head">
            <h2>${escapeHtml(title)}</h2>
            <button class="sheet-close" data-action="close-sheet" type="button">${options.closeTitle || "Закрыть"}</button>
          </div>
          <div class="sheet-body">${bodyHtml}</div>
        </div>
      </div>`;
    document.body.style.overflow = "hidden";
  }

  function closeSheet() {
    sheetRoot().innerHTML = "";
    document.body.style.overflow = "";
  }

  // Ввод суммы -------------------------------------------------------------

  let amountContext = null;

  function openAmountSheet(goalId, kind) {
    const goal = state.goals.find((item) => item.id === goalId);
    if (!goal) return;
    amountContext = { goalId, kind, text: "", note: "" };
    renderAmountSheet();
  }

  function amountValue() {
    return round2(parseFloat((amountContext.text || "0").replace(",", ".")) || 0);
  }

  function amountDisplay() {
    if (!amountContext.text) return "0";
    const [head, tail] = amountContext.text.split(",");
    const grouped = (head || "0").replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    return tail === undefined ? grouped : `${grouped},${tail}`;
  }

  function renderAmountSheet() {
    const goal = state.goals.find((item) => item.id === amountContext.goalId);
    if (!goal) return closeSheet();

    const isDeposit = amountContext.kind === "deposit";
    const value = amountValue();
    const tooMuch = !isDeposit && value > saved(goal);
    const canSubmit = value > 0 && !tooMuch;

    const hint = tooMuch
      ? `<span class="amount-hint is-error">Больше, чем накоплено: ${formatMoney(saved(goal))}</span>`
      : isDeposit && remaining(goal) > 0
        ? `<span class="amount-hint">До цели осталось ${formatMoney(remaining(goal))}</span>`
        : `<span class="amount-hint"></span>`;

    const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ",", "0", "⌫"];

    openSheet(
      goal.title,
      `
      <div class="segmented">
        <button class="${isDeposit ? "is-active" : ""}" data-action="amount-kind" data-value="deposit">Пополнить</button>
        <button class="${!isDeposit ? "is-active" : ""}" data-action="amount-kind" data-value="withdrawal">Снять</button>
      </div>

      <div class="amount-display">
        <div class="amount-value" style="color:${amountContext.text ? "var(--text)" : "var(--text-3)"}">
          ${isDeposit ? "+" : "−"}${amountDisplay()} <span style="color:var(--text-2)">${currency().symbol}</span>
        </div>
        ${hint}
      </div>

      <div class="quick-row">
        ${currency()
          .quick.map(
            (amount) =>
              `<button class="quick" data-action="amount-quick" data-value="${amount}"
                 style="color:${accent(goal)};background:${palette(goal).colors[1]}22">+${formatMoney(amount)}</button>`,
          )
          .join("")}
        ${
          isDeposit && remaining(goal) > 0
            ? `<button class="quick" data-action="amount-fill" style="background:var(--surface-sunken);color:var(--text-2)">До цели</button>`
            : ""
        }
      </div>

      <div class="field">
        <input type="text" id="amount-note" placeholder="Комментарий (необязательно)" value="${escapeHtml(amountContext.note)}" />
      </div>

      <div class="pad">
        ${keys.map((key) => `<button data-action="amount-key" data-value="${key}">${key}</button>`).join("")}
      </div>

      <button class="btn btn-primary" style="width:100%;background:${gradient(goal)};box-shadow:0 8px 16px ${accent(goal)}59" data-action="amount-submit" ${
        canSubmit ? "" : "disabled"
      }>${isDeposit ? "Пополнить" : "Снять"}</button>`,
      { closeTitle: "Отмена" },
    );

    const noteInput = document.getElementById("amount-note");
    if (noteInput) {
      noteInput.addEventListener("input", (event) => {
        amountContext.note = event.target.value;
      });
    }
  }

  function pressAmountKey(key) {
    const context = amountContext;
    if (key === "⌫") {
      context.text = context.text.slice(0, -1);
    } else if (key === ",") {
      if (!context.text.includes(",")) context.text = context.text ? `${context.text},` : "0,";
    } else {
      const [, tail] = context.text.split(",");
      if (tail !== undefined && tail.length >= 2) return;
      if (tail === undefined && context.text.replace(/\D/g, "").length >= 9) return;
      context.text = context.text === "0" ? key : context.text + key;
    }
    renderAmountSheet();
  }

  function submitAmount() {
    const goal = state.goals.find((item) => item.id === amountContext.goalId);
    if (!goal) return closeSheet();

    const value = amountValue();
    const wasCompleted = isCompleted(goal);
    goal.transactions.push({
      id: uuid(),
      amount: value,
      kind: amountContext.kind,
      date: new Date().toISOString(),
      note: amountContext.note.trim(),
    });
    save();

    const justCompleted = !wasCompleted && isCompleted(goal);
    closeSheet();
    render();

    if (justCompleted) {
      celebrate(palette(goal).colors);
      toast(`Цель «${goal.title}» закрыта 🎉`);
    }
  }

  // Экран цели -------------------------------------------------------------

  function openGoalSheet(goalId) {
    const goal = state.goals.find((item) => item.id === goalId);
    if (!goal) return;

    const milestones = [0.25, 0.5, 0.75, 1]
      .map((milestone) => {
        const done = progress(goal) >= milestone - 0.0001;
        return `<div class="milestone ${done ? "is-done" : ""}">
          <i style="${done ? `background:${gradient(goal)};color:#fff` : ""}">${done ? "✓" : "🔒"}</i>${Math.round(milestone * 100)}%
        </div>`;
      })
      .join("");

    const facts = [
      ["Осталось накопить", formatMoney(remaining(goal))],
      weeklyPace(goal) ? ["Нужный темп", `${formatMoney(weeklyPace(goal))} в неделю`] : null,
      ["Операций", String(goal.transactions.length)],
      goal.deadline ? ["Срок", new Date(`${goal.deadline}T00:00:00`).toLocaleDateString("ru-RU")] : null,
    ].filter(Boolean);

    const history = [...goal.transactions]
      .sort((a, b) => new Date(b.date) - new Date(a.date))
      .map((item) => {
        const deposit = item.kind === "deposit";
        return `
          <div class="history-row">
            <span class="history-icon" style="background:${deposit ? "rgba(46,148,100,.12)" : "rgba(192,80,63,.12)"};color:${
              deposit ? "var(--positive)" : "var(--negative)"
            }">${deposit ? "↓" : "↑"}</span>
            <span style="min-width:0">
              <div class="history-note">${escapeHtml(item.note || (deposit ? "Пополнение" : "Снятие"))}</div>
              <div class="history-date">${new Date(item.date).toLocaleString("ru-RU", {
                day: "numeric",
                month: "short",
                hour: "2-digit",
                minute: "2-digit",
              })}</div>
            </span>
            <span class="history-amount" style="color:${deposit ? "var(--positive)" : "var(--negative)"}">
              ${deposit ? "+" : "−"}${formatMoney(item.amount)}
            </span>
            <button class="history-delete" data-action="delete-transaction" data-id="${goal.id}" data-tx="${item.id}"
              aria-label="Удалить операцию">✕</button>
          </div>`;
      })
      .join("");

    openSheet(
      goal.title,
      `
      <div class="card detail-hero">
        ${ring(
          progress(goal),
          208,
          16,
          palette(goal).colors,
          `<span class="goal-badge" style="width:44px;height:44px;font-size:20px;background:${gradient(goal)}">${goal.icon}</span>
           <span class="detail-amount">${formatMoney(saved(goal))}</span>
           <span style="font-size:13px;color:var(--text-2)">из ${formatMoney(goal.target)}</span>`,
        )}
        <div style="display:flex;gap:8px;flex-wrap:wrap;justify-content:center">
          <span class="chip" style="color:${accent(goal)};background:${palette(goal).colors[1]}22">${percentText(progress(goal))}</span>
          ${
            isCompleted(goal)
              ? `<span class="chip" style="color:var(--positive);background:rgba(46,148,100,.14)">✓ Цель достигнута</span>`
              : deadlineText(goal)
                ? `<span class="chip" style="color:var(--text-2);background:var(--surface-sunken)">${escapeHtml(deadlineText(goal))}</span>`
                : ""
          }
        </div>
        ${goal.note ? `<p class="setting-note" style="text-align:center">${escapeHtml(goal.note)}</p>` : ""}
      </div>

      <div class="row-2">
        <button class="btn btn-primary" style="background:${gradient(goal)};box-shadow:0 8px 16px ${accent(goal)}59" data-action="quick-add" data-id="${goal.id}">Пополнить</button>
        <button class="btn btn-secondary narrow" data-action="withdraw" data-id="${goal.id}" ${
          saved(goal) > 0 ? "" : "disabled"
        } aria-label="Снять деньги">↑</button>
      </div>

      <div class="card">
        <div class="section-head"><div><h2>Вехи</h2><p>Отмечаем каждый шаг</p></div></div>
        <div class="milestones" style="margin-top:14px">${milestones}</div>
      </div>

      <div class="card facts">
        ${facts.map(([title, value]) => `<div class="fact"><span class="fact-title">${title}</span><span class="fact-value">${value}</span></div>`).join("")}
      </div>

      <div class="card">
        <div class="section-head"><div><h2>История</h2><p>${
          goal.transactions.length
            ? `${goal.transactions.length} ${plural(goal.transactions.length, "операция", "операции", "операций")}`
            : "Пока пусто"
        }</p></div></div>
        <div style="margin-top:8px">${history || `<p class="setting-note">Первое пополнение появится здесь.</p>`}</div>
      </div>

      <div class="row-2">
        <button class="btn btn-secondary" data-action="edit-goal" data-id="${goal.id}">Редактировать</button>
        <button class="btn btn-secondary" style="color:var(--negative)" data-action="delete-goal" data-id="${goal.id}">Удалить</button>
      </div>`,
    );
  }

  // Редактор цели ----------------------------------------------------------

  let editorContext = null;

  function openEditor(goalId) {
    const existing = goalId ? state.goals.find((item) => item.id === goalId) : null;
    editorContext = existing
      ? { ...existing, transactions: undefined }
      : { id: null, title: "", target: "", icon: "🎯", palette: "gold", deadline: "", note: "" };
    renderEditor();
  }

  function renderEditor() {
    const context = editorContext;
    openSheet(
      context.id ? "Редактирование" : "Новая цель",
      `
      <div class="card field">
        <span class="field-label">Название</span>
        <input type="text" id="editor-title" placeholder="Например, отпуск в Японии" value="${escapeHtml(context.title)}" />
        <span class="field-label" style="margin-top:8px">Сумма цели, ${currency().symbol}</span>
        <input type="number" inputmode="decimal" id="editor-target" placeholder="0" value="${context.target}" />
        <span class="field-label" style="margin-top:8px">Срок (необязательно)</span>
        <input type="date" id="editor-deadline" value="${context.deadline || ""}" />
      </div>

      <div class="card field">
        <span class="field-label">Цвет</span>
        <div class="palette-row">
          ${Object.entries(PALETTES)
            .map(
              ([id, item]) =>
                `<button class="palette-dot ${context.palette === id ? "is-active" : ""}" data-action="editor-palette" data-value="${id}"
                   style="background:linear-gradient(135deg, ${item.colors[0]}, ${item.colors[1]})" aria-label="${item.title}"></button>`,
            )
            .join("")}
        </div>
        <span class="field-label" style="margin-top:8px">Иконка</span>
        <div class="picker-grid">
          ${ICONS.map(
            (icon) =>
              `<button class="${context.icon === icon ? "is-active" : ""}" data-action="editor-icon" data-value="${icon}">${icon}</button>`,
          ).join("")}
        </div>
      </div>

      <div class="card field">
        <span class="field-label">Заметка</span>
        <input type="text" id="editor-note" placeholder="Зачем эта цель" value="${escapeHtml(context.note)}" />
      </div>

      <button class="btn btn-primary" style="width:100%" data-action="editor-save">Сохранить</button>`,
      { closeTitle: "Отмена" },
    );

    const bind = (id, key) => {
      const input = document.getElementById(id);
      if (input) input.addEventListener("input", (event) => (editorContext[key] = event.target.value));
    };
    bind("editor-title", "title");
    bind("editor-target", "target");
    bind("editor-deadline", "deadline");
    bind("editor-note", "note");
  }

  function saveEditor() {
    const context = editorContext;
    const title = (context.title || "").trim();
    const target = round2(parseFloat(String(context.target).replace(",", ".")) || 0);

    if (!title || target <= 0) {
      toast("Заполните название и сумму");
      return;
    }

    if (context.id) {
      const goal = state.goals.find((item) => item.id === context.id);
      Object.assign(goal, { title, target, icon: context.icon, palette: context.palette, deadline: context.deadline || null, note: (context.note || "").trim() });
    } else {
      state.goals.push({
        id: uuid(),
        title,
        target,
        icon: context.icon,
        palette: context.palette,
        deadline: context.deadline || null,
        note: (context.note || "").trim(),
        createdAt: new Date().toISOString(),
        transactions: [],
      });
    }

    save();
    closeSheet();
    render();
  }

  // --- Эффекты -----------------------------------------------------------

  function celebrate(colors) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const root = document.getElementById("confetti-root");
    const palette = [...colors, "#f0c070", "#ffffff"];
    const pieces = [];

    for (let index = 0; index < 70; index += 1) {
      const piece = document.createElement("i");
      piece.className = "confetti-piece";
      piece.style.left = `${Math.random() * 100}%`;
      piece.style.background = palette[index % palette.length];
      piece.style.animationDuration = `${1.6 + Math.random()}s`;
      piece.style.animationDelay = `${Math.random() * 0.4}s`;
      if (index % 5 === 0) piece.style.borderRadius = "50%";
      root.appendChild(piece);
      pieces.push(piece);
    }

    setTimeout(() => pieces.forEach((piece) => piece.remove()), 3200);
  }

  function toast(message) {
    const existing = document.querySelector(".toast");
    if (existing) existing.remove();
    const element = document.createElement("div");
    element.className = "toast";
    element.textContent = message;
    document.body.appendChild(element);
    setTimeout(() => element.remove(), 2600);
  }

  // --- Демо-данные -------------------------------------------------------

  function daysAgo(days) {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date.toISOString();
  }

  function dateAhead(days) {
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date.toISOString().slice(0, 10);
  }

  function loadDemo() {
    state.goals = [
      {
        id: uuid(),
        title: "Отпуск в Японии",
        target: 420000,
        icon: "✈️",
        palette: "ocean",
        deadline: dateAhead(180),
        note: "Токио, Киото и Осака весной",
        createdAt: daysAgo(120),
        transactions: [
          { id: uuid(), amount: 40000, kind: "deposit", date: daysAgo(110), note: "Премия" },
          { id: uuid(), amount: 25000, kind: "deposit", date: daysAgo(82), note: "" },
          { id: uuid(), amount: 30000, kind: "deposit", date: daysAgo(54), note: "Отложил с зарплаты" },
          { id: uuid(), amount: 12000, kind: "withdrawal", date: daysAgo(40), note: "Срочный ремонт" },
          { id: uuid(), amount: 35000, kind: "deposit", date: daysAgo(21), note: "" },
          { id: uuid(), amount: 18000, kind: "deposit", date: daysAgo(4), note: "" },
        ],
      },
      {
        id: uuid(),
        title: "Подушка безопасности",
        target: 600000,
        icon: "🩺",
        palette: "forest",
        deadline: null,
        note: "Три месяца привычных расходов",
        createdAt: daysAgo(240),
        transactions: [
          { id: uuid(), amount: 90000, kind: "deposit", date: daysAgo(200), note: "" },
          { id: uuid(), amount: 60000, kind: "deposit", date: daysAgo(150), note: "" },
          { id: uuid(), amount: 75000, kind: "deposit", date: daysAgo(96), note: "" },
          { id: uuid(), amount: 55000, kind: "deposit", date: daysAgo(63), note: "" },
          { id: uuid(), amount: 48000, kind: "deposit", date: daysAgo(30), note: "" },
          { id: uuid(), amount: 22000, kind: "deposit", date: daysAgo(9), note: "" },
        ],
      },
      {
        id: uuid(),
        title: "MacBook Pro",
        target: 240000,
        icon: "💻",
        palette: "graphite",
        deadline: dateAhead(45),
        note: "",
        createdAt: daysAgo(70),
        transactions: [
          { id: uuid(), amount: 60000, kind: "deposit", date: daysAgo(60), note: "" },
          { id: uuid(), amount: 45000, kind: "deposit", date: daysAgo(32), note: "" },
          { id: uuid(), amount: 38000, kind: "deposit", date: daysAgo(12), note: "" },
        ],
      },
      {
        id: uuid(),
        title: "Новый велосипед",
        target: 85000,
        icon: "🚲",
        palette: "sunset",
        deadline: null,
        note: "",
        createdAt: daysAgo(150),
        transactions: [
          { id: uuid(), amount: 35000, kind: "deposit", date: daysAgo(140), note: "" },
          { id: uuid(), amount: 30000, kind: "deposit", date: daysAgo(100), note: "" },
          { id: uuid(), amount: 20000, kind: "deposit", date: daysAgo(66), note: "" },
        ],
      },
    ];
    save();
    render();
  }

  // --- Рендер и события --------------------------------------------------

  function applyTheme() {
    const root = document.documentElement;
    root.dataset.theme = state.settings.theme === "system" ? "" : state.settings.theme;
  }

  function render() {
    applyTheme();
    const screen = document.getElementById("screen");
    const title = document.getElementById("screen-title");
    const headerAction = document.getElementById("header-action");

    if (activeTab === "goals") {
      title.textContent = "Копилка";
      headerAction.style.display = "";
      screen.innerHTML = renderGoals();
    } else if (activeTab === "stats") {
      title.textContent = "Статистика";
      headerAction.style.display = "none";
      screen.innerHTML = renderStats();
    } else {
      title.textContent = "Настройки";
      headerAction.style.display = "none";
      screen.innerHTML = renderSettings();
    }

    document.querySelectorAll(".tab").forEach((tab) => {
      const isActive = tab.dataset.tab === activeTab;
      tab.classList.toggle("is-active", isActive);
      tab.setAttribute("aria-selected", String(isActive));
    });
  }

  const actions = {
    "new-goal": () => openEditor(null),
    "load-demo": () => loadDemo(),
    reset: () => {
      if (!confirm("Удалить все цели и историю?")) return;
      state = defaultState();
      save();
      render();
      toast("Данные удалены");
    },
    "open-goal": (element) => openGoalSheet(element.dataset.id),
    "quick-add": (element) => openAmountSheet(element.dataset.id, "deposit"),
    withdraw: (element) => openAmountSheet(element.dataset.id, "withdrawal"),
    "amount-kind": (element) => {
      amountContext.kind = element.dataset.value;
      renderAmountSheet();
    },
    "amount-key": (element) => pressAmountKey(element.dataset.value),
    "amount-quick": (element) => {
      amountContext.text = String(amountValue() + Number(element.dataset.value)).replace(".", ",");
      renderAmountSheet();
    },
    "amount-fill": () => {
      const goal = state.goals.find((item) => item.id === amountContext.goalId);
      amountContext.text = String(remaining(goal)).replace(".", ",");
      renderAmountSheet();
    },
    "amount-submit": () => submitAmount(),
    "edit-goal": (element) => openEditor(element.dataset.id),
    "editor-palette": (element) => {
      editorContext.palette = element.dataset.value;
      renderEditor();
    },
    "editor-icon": (element) => {
      editorContext.icon = element.dataset.value;
      renderEditor();
    },
    "editor-save": () => saveEditor(),
    "delete-goal": (element) => {
      if (!confirm("Удалить цель вместе с историей операций?")) return;
      state.goals = state.goals.filter((goal) => goal.id !== element.dataset.id);
      save();
      closeSheet();
      render();
    },
    "delete-transaction": (element) => {
      const goal = state.goals.find((item) => item.id === element.dataset.id);
      if (!goal) return;
      goal.transactions = goal.transactions.filter((item) => item.id !== element.dataset.tx);
      save();
      openGoalSheet(goal.id);
      render();
    },
    "set-theme": (element) => {
      state.settings.theme = element.dataset.value;
      save();
      render();
    },
    "set-currency": (element) => {
      state.settings.currency = element.dataset.value;
      save();
      render();
    },
    "close-sheet": () => closeSheet(),
  };

  document.addEventListener("click", (event) => {
    const backdrop = event.target.closest(".sheet-backdrop");
    if (backdrop && event.target === backdrop) {
      closeSheet();
      return;
    }

    const trigger = event.target.closest("[data-action]");
    if (!trigger) return;

    const action = actions[trigger.dataset.action];
    if (action) {
      event.preventDefault();
      action(trigger);
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeSheet();
  });

  document.querySelectorAll(".tab").forEach((tab) => {
    tab.addEventListener("click", () => {
      activeTab = tab.dataset.tab;
      render();
    });
  });

  document.getElementById("header-action").addEventListener("click", () => openEditor(null));

  state = load();

  // На лендинге демо встроено в макет телефона: показываем сразу заполненный экран.
  if (!state.goals.length && new URLSearchParams(location.search).has("demo")) {
    loadDemo();
  } else {
    render();
  }
})();
