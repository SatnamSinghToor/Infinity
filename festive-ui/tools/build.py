#!/usr/bin/env python3
"""
Static site generator for the Diwali storefront recreation.

Run:  python3 tools/build.py
It writes ../index.html and ../diwali.html from the data below so the shipped
pages are plain, dependency-free, fully semantic HTML (JS only adds behaviour).
"""
from __future__ import annotations
import html
import math
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMG = "assets/img/"


def e(s) -> str:
    return html.escape(str(s), quote=True)


def img(name: str) -> str:
    return f"{IMG}{name}.jpg"


FILLED_ICONS = {"ornament", "lotus", "spark", "star", "bolt"}


def icon(name: str, cls: str = "") -> str:
    kind = " i--fill" if name in FILLED_ICONS else ""
    return f'<svg class="i{kind} {cls}" aria-hidden="true"><use href="#i-{name}"></use></svg>'


# --------------------------------------------------------------------------
# Shared icon sprite. All icons are stroked line art unless noted otherwise.
# --------------------------------------------------------------------------
SPRITE = """<svg class="sr-only" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">
  <symbol id="i-search" viewBox="0 0 24 24"><circle cx="10.7" cy="10.7" r="6.6"/><path d="m15.6 15.6 4.7 4.7"/></symbol>
  <symbol id="i-voice" viewBox="0 0 24 24"><path d="M3.5 10v4M7 7.5v9M10.5 4.5v15M14 7.5v9M17.5 5v14M21 9.5v5"/></symbol>
  <symbol id="i-user" viewBox="0 0 24 24"><circle cx="12" cy="8" r="3.6"/><path d="M5 20.2c0-3.6 3.1-6 7-6s7 2.4 7 6"/></symbol>
  <symbol id="i-wallet" viewBox="0 0 24 24"><rect x="3" y="5.6" width="18" height="12.8" rx="2.6"/><path d="M3 10h18"/><circle cx="17.2" cy="14.3" r="1.2" fill="currentColor" stroke="none"/></symbol>
  <symbol id="i-chevron-down" viewBox="0 0 24 24"><path d="m5.5 8.5 6.5 6.5 6.5-6.5"/></symbol>
  <symbol id="i-arrow-right" viewBox="0 0 24 24"><path d="M4 12h15m-6.2-6.2L19 12l-6.2 6.2"/></symbol>
  <symbol id="i-arrow-left" viewBox="0 0 24 24"><path d="M20 12H5m6.2-6.2L5 12l6.2 6.2"/></symbol>
  <symbol id="i-arrow-up" viewBox="0 0 24 24"><path d="M12 20V4m-6 6 6-6 6 6"/></symbol>
  <symbol id="i-heart" viewBox="0 0 24 24"><path d="M12 20.3S4.4 15.6 4.4 10.4A4.1 4.1 0 0 1 12 8.1a4.1 4.1 0 0 1 7.6 2.3c0 5.2-7.6 9.9-7.6 9.9Z"/></symbol>
  <symbol id="i-clock" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 6.8v5.5l3.6 2.1"/></symbol>
  <symbol id="i-star" viewBox="0 0 24 24"><path d="m12 2.6 2.9 5.9 6.6.9-4.8 4.7 1.2 6.6L12 17.6l-5.9 3.1 1.2-6.6-4.8-4.7 6.6-.9Z"/></symbol>
  <symbol id="i-bolt" viewBox="0 0 24 24"><path d="M13.4 2.2 4.8 13.4h6.1l-.5 8.4 8.8-11.6h-6.2Z"/></symbol>
  <symbol id="i-cart" viewBox="0 0 24 24"><path d="M2.8 4h2.3l2.4 11.3a1.7 1.7 0 0 0 1.7 1.3h8.4a1.7 1.7 0 0 0 1.7-1.3L20.9 8H6.4"/><circle cx="10" cy="20" r="1.3"/><circle cx="17.6" cy="20" r="1.3"/></symbol>
  <symbol id="i-home" viewBox="0 0 24 24"><path d="M3.4 10.3 12 3.6l8.6 6.7v8.9a1.5 1.5 0 0 1-1.5 1.5h-4.3v-6.2H9.2v6.2H4.9a1.5 1.5 0 0 1-1.5-1.5Z"/></symbol>
  <symbol id="i-orders" viewBox="0 0 24 24"><path d="M3.8 8h16.4l-1.2 11.3a1.6 1.6 0 0 1-1.6 1.4H6.6a1.6 1.6 0 0 1-1.6-1.4Z"/><path d="M8.4 8V6.1a3.6 3.6 0 0 1 7.2 0V8"/></symbol>
  <symbol id="i-grid" viewBox="0 0 24 24"><rect x="3.4" y="3.4" width="7" height="7" rx="1.6"/><rect x="13.6" y="3.4" width="7" height="7" rx="1.6"/><rect x="3.4" y="13.6" width="7" height="7" rx="1.6"/><rect x="13.6" y="13.6" width="7" height="7" rx="1.6"/></symbol>
  <symbol id="i-print" viewBox="0 0 24 24"><rect x="3.6" y="7.6" width="16.8" height="9.4" rx="1.8"/><path d="M7.2 7.6V3.8h9.6v3.8M7.2 13.8h9.6v6.4H7.2Z"/></symbol>
  <symbol id="i-all" viewBox="0 0 24 24"><rect x="3.4" y="3.4" width="7.2" height="7.2" rx="1.8"/><rect x="13.4" y="3.4" width="7.2" height="7.2" rx="1.8"/><rect x="3.4" y="13.4" width="7.2" height="7.2" rx="1.8"/><rect x="13.4" y="13.4" width="7.2" height="7.2" rx="1.8"/></symbol>
  <symbol id="i-diya" viewBox="0 0 24 24"><path d="M12 2.6c2.3 1.9 3.2 3.6 3.2 5.1 0 1.8-1.4 3-3.2 3s-3.2-1.2-3.2-3c0-1.5.9-3.2 3.2-5.1Z"/><path d="M3.8 13h16.4l-1.7 4.6a2.2 2.2 0 0 1-2 1.4H7.5a2.2 2.2 0 0 1-2-1.4Z"/><path d="M8 21h8"/></symbol>
  <symbol id="i-party" viewBox="0 0 24 24"><path d="M5.6 16.6h12.8l-1.5-2.4V10a4.9 4.9 0 0 0-9.8 0v4.2Z"/><path d="M10.2 18.5a1.9 1.9 0 0 0 3.6 0"/><path d="M12 3.2V2"/></symbol>
  <symbol id="i-headphones" viewBox="0 0 24 24"><path d="M3.8 13.4v-1.2a8.2 8.2 0 0 1 16.4 0v1.2"/><rect x="2.8" y="12.6" width="4.2" height="7.4" rx="2.1"/><rect x="17" y="12.6" width="4.2" height="7.4" rx="2.1"/></symbol>
  <symbol id="i-beauty" viewBox="0 0 24 24"><rect x="4.4" y="8.4" width="5.4" height="11.8" rx="1.5"/><path d="M6 8.4V5.2h2.2v3.2"/><rect x="14.2" y="10.4" width="5.4" height="9.8" rx="1.5"/><path d="M15.8 10.4V6.6H18v3.8"/><path d="M4.4 12.6h5.4M14.2 14.4h5.4"/></symbol>
  <symbol id="i-gift" viewBox="0 0 24 24"><rect x="3.2" y="9" width="17.6" height="11.4" rx="1.6"/><path d="M3.2 13h17.6M12 9v11.4"/><path d="M12 9C8.6 9 6.6 8 6.6 6.3c0-1.1 1-1.8 2.1-1.8C10.5 4.5 12 6.7 12 9Zm0 0c3.4 0 5.4-1 5.4-2.7 0-1.1-1-1.8-2.1-1.8C13.5 4.5 12 6.7 12 9Z"/></symbol>
  <symbol id="i-spark" viewBox="0 0 24 24"><path d="M12 2.2 14.5 9.5 21.8 12l-7.3 2.5L12 21.8l-2.5-7.3L2.2 12l7.3-2.5Z"/></symbol>
  <symbol id="i-ornament" viewBox="0 0 24 24"><path d="M12 2.4 14.3 9.7 21.6 12l-7.3 2.3L12 21.6l-2.3-7.3L2.4 12l7.3-2.3Z"/><path d="M4.4 4.4h2.4v2.4H4.4zM17.2 4.4h2.4v2.4h-2.4zM4.4 17.2h2.4v2.4H4.4zM17.2 17.2h2.4v2.4h-2.4z" fill="currentColor" stroke="none"/></symbol>
  <symbol id="i-lotus" viewBox="0 0 24 24"><path d="M12 3.2c-2.2 3-3.1 5.8-3.1 8.2 0 3.7 1.3 6.1 3.1 7.4 1.8-1.3 3.1-3.7 3.1-7.4 0-2.4-.9-5.2-3.1-8.2Z"/><path d="M9.5 7.5C7.2 8 5.1 10 4.1 12.7c-.9 2.4-.2 4.5 1.3 5.9 1-2.8 2.5-4.9 4.8-6.3Z"/><path d="M14.5 7.5c2.3.5 4.4 2.5 5.4 5.2.9 2.4.2 4.5-1.3 5.9-1-2.8-2.5-4.9-4.8-6.3Z"/><path d="M2.8 18.4c3 2 6.1 3 9.2 3s6.2-1 9.2-3c-2.5 3.3-5.7 4.6-9.2 4.6s-6.7-1.3-9.2-4.6Z"/></symbol>
</svg>"""


def strand(variant: str = "top") -> str:
    """A draped string of fairy lights, generated as an inline SVG."""
    pts = []
    for i in range(101):
        x = i * 10
        y = 4 + 20 * (0.5 - 0.5 * math.cos(6 * math.pi * i / 100))
        pts.append((x, y))
    path = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts)
    bulbs = []
    for j in range(1, 26):
        x = j * 1000 / 26
        y = 4 + 20 * (0.5 - 0.5 * math.cos(6 * math.pi * x / 1000))
        d = round(j * 0.11, 2)
        bulbs.append(
            f'<g class="bulb" style="animation-delay:{d}s">'
            f'<line x1="{x:.1f}" y1="{y:.1f}" x2="{x:.1f}" y2="{y+5.2:.1f}" stroke="#4B2A12" stroke-width="1.1"/>'
            f'<circle cx="{x:.1f}" cy="{y+8:.1f}" r="6.4" fill="#FFC65C" opacity=".22"/>'
            f'<circle cx="{x:.1f}" cy="{y+8:.1f}" r="3.1" fill="#FFD979"/>'
            f'<circle cx="{x-0.9:.1f}" cy="{y+6.9:.1f}" r="1.1" fill="#FFF6D6" opacity=".9"/>'
            f"</g>"
        )
    return (
        f'<svg class="strand strand--{variant}" viewBox="0 0 1000 42" preserveAspectRatio="none" aria-hidden="true">'
        f'<path d="{path}" fill="none" stroke="#4A2A13" stroke-width="1.3" opacity=".85"/>'
        + "".join(bulbs)
        + "</svg>"
    )


# --------------------------------------------------------------------------
# Product data
# --------------------------------------------------------------------------
def P(name, image, qty, price, mrp, offer="", *, hl=False, chip="", rating=None,
      reviews="", time="16 mins", stock="", ad=False, badge="", similar=True, variants=""):
    return dict(name=name, image=image, qty=qty, price=price, mrp=mrp, offer=offer,
                hl=hl, chip=chip, rating=rating, reviews=reviews, time=time,
                stock=stock, ad=ad, badge=badge, similar=similar, variants=variants)


PRODUCTS = {
    "festive_vibes": [
        P("Decorated Clay Divine Diya Set by Aravi", "diya-3", "12 pcs", "₹189", "₹350", "Price Drop", hl=True, chip='2" x 2"', similar=True),
        P("Decorated Clay Diya Set by House Of Festivals", "diya-2", "3 pcs", "₹179", "₹350", "₹171 OFF", chip='3.1"', similar=True),
        P("Decorated Clay Dual Shaded Diya Set by Aravi", "diya-4", "12 pcs", "₹189", "₹350", "Price Drop", hl=True, chip='2.5" x 2.5" x 0.8"', similar=True),
        P("Hand Painted Clay Diya Set by House Of Festivals", "diya-1", "12 pcs", "₹199", "₹399", "50% OFF", chip="4 cm", similar=True),
        P("Kuber Deepak Oil Lamp Set by Aravi", "diya-5", "21 pcs", "₹149", "₹299", "₹150 OFF", chip="Cotton wicks", similar=True),
    ],
    "entrance": [
        P("Urli Soy Wax Candle Set (Vanilla, Oudh) by Auradecor", "urli-1", "2 pcs", "₹565", "₹2,500", "₹600 OFF", chip="Soy Wax", rating=4, reviews="362", stock="1 left", time="16 mins", similar=True),
        P("Elegant Urli Bowl for Festive & Pooja Decor", "urli-3", "1 pc", "₹399", "₹999", "₹600 OFF", chip='Metal | 10" x 10"', rating=4, reviews="82", stock="2 left", similar=True),
        P("Urli Scented Candle (Myrrh & Amber) Set by Pa", "candle-2", "3 pcs", "₹399", "₹899", "₹500 OFF", chip="Soy Wax", similar=True),
        P("Flower Shaped Urli Stand Set - Aksharveda", "urli-2", "2 pcs", "₹449", "₹700", "₹251 OFF", chip="Steel", similar=True),
        P("Ganesha Shadow Diyas with Attached Stand", "brassdiya-5", "1 pc", "₹279", "₹450", "₹171 OFF", chip="Steel", similar=True),
        P("Lotus Diya Standing Urli Bowl Set", "urli-5", "2 pcs", "₹599", "₹1,000", "₹401 OFF", chip="Steel", similar=True),
    ],
    "gifts": [
        P("Ferrero Rocher Golden Diya Chocolate Gift Pack", "chocolate-1", "200 g", "₹999", "₹1,499", "₹500 OFF", badge="Limited edition", similar=True),
        P("Orika Grill & Chill Diwali Gift Box with Marinades", "hamper-4", "76 g", "₹499", "₹799", "₹300 OFF", badge="GIFT READY BOX", stock="2 left", similar=True),
        P("Cadbury Celebrations Kesar Pista Milky Mithai", "chocolate-5", "108 g", "₹229", "₹300", "23% OFF on MRP", similar=True),
        P("Luxury Diwali Hamper with Dry Fruits & Chocolates", "hamper-1", "1 box", "₹799", "₹1,299", "₹500 OFF", similar=True),
        P("Assorted Chocolate & Sweet Celebration Box", "chocolate-3", "93 g", "₹349", "₹499", "30% OFF", similar=True),
    ],
    "lights": [
        P("Warm White 10 m Pixel Light by WAAN", "lights-1", "36 Bulbs", "₹69", "₹299", "Price Drop", hl=True, chip="Adapter", variants="3 options", rating=4, reviews="3,836", similar=False),
        P("Warm White 2.5 x 0.7 m Star Curtain String Lights", "lights-2", "96 Bulbs", "₹319", "₹799", "", chip="12 pcs | 2 Pin Plug", variants="", rating=4, reviews="149", similar=False),
        P("Multicolour 10 m Pixel Light by WAAN", "lights-3", "36 Bulbs", "₹79", "₹299", "Price Drop", hl=True, variants="2 options", rating=4, reviews="546", similar=False),
        P("Copper Wire Fairy String Lights with Remote", "lights-4", "100 LED", "₹249", "₹699", "64% OFF", variants="2 options", rating=4, reviews="1,204", similar=False),
        P("Globe String Lights Warm White (USB)", "lights-5", "40 LED", "₹199", "₹499", "60% OFF", variants="", rating=4, reviews="918", similar=False),
    ],
    "warmth": [
        P("Pearl & Bead Door Hanging with Bell - Satvik", "toran-1", "2 pcs", "₹299", "₹799", "₹500 OFF", chip='Plastic | 54" x 2"', similar=True),
        P("Flower Shaped Urli Stand Set - Aksharveda", "urli-2", "2 pcs", "₹449", "₹700", "₹251 OFF", chip="Steel", similar=True),
        P("Urli Scented Candle (Myrrh & Amber) Set", "candle-4", "3 pcs", "₹399", "₹899", "₹500 OFF", chip="Soy Wax", similar=True),
        P("Marigold Toran with Bells for Entrance", "toran-2", "1 pc", "₹349", "₹699", "50% OFF", chip="5 ft", similar=True),
        P("Designer Tealight Candle Gift Set", "candle-5", "8 pcs", "₹279", "₹599", "₹320 OFF", chip="Unscented", similar=True),
    ],
    "celebrations": [
        P("Shubh Labh Swastik & Charan Sticker (Gold)", "rangoli-2", "6 pcs", "₹79", "₹199", "₹120 OFF", similar=True),
        P("Lakshmi Charan Sticker (Red) - DiaCraft", "rangoli-3", "10 pcs", "₹49", "₹100", "51% OFF on MRP", similar=True),
        P("Divine Footprints Mandala Floor Sticker", "rangoli-1", "1 pc", "₹51", "₹249", "₹198 OFF", similar=True),
        P("Colourful Acrylic Rangoli Set for Floor Decor", "rangoli-4", "38 pcs", "₹199", "₹599", "66% OFF", similar=True),
        P("Lotus Rangoli Floor Stickers - Self Adhesive", "rangoli-5", "11 pcs", "₹149", "₹399", "62% OFF", similar=True),
    ],
    "corner": [
        P("myTrident Comfort Living Hand Towel 400 GSM", "towel-1", "2 pcs", "₹199", "₹399", "", chip="Red", rating=5, reviews="1,012", ad=True, similar=False),
        P("Rooted Single Red Rose Dried Flower Bouquet", "rose-2", "Dried", "₹119", "₹299", "", chip="1 Stem", rating=4, reviews="6,014", similar=False),
        P("myTrident Comfort Living Hand Towel 400 GSM", "towel-3", "2 pcs", "₹199", "₹399", "Half Price", chip="400 GSM", rating=4, reviews="1,232", stock="1 left", ad=True, similar=False),
        P("Artificial Red Rose Bouquet in Ceramic Vase", "rose-3", "1 pc", "₹449", "₹899", "50% OFF", chip="Ceramic", rating=4, reviews="814", similar=False),
        P("Premium Cotton Hand Towel Gift Set", "towel-2", "3 pcs", "₹299", "₹599", "50% OFF", chip="100% Cotton", rating=4, reviews="2,106", similar=False),
    ],
    "rituals": [
        P("Shri Ram Darbar Photo Frame for Pooja", "pooja-1", "1 pc", "₹199", "₹399", "50% OFF", chip="8.6 inch", similar=True),
        P("Loban Cups & Dhoop for Daily Pooja", "brassdiya-1", "12 pcs", "₹99", "₹199", "50% OFF", chip="Herbal", similar=True),
        P("Panchmeva Hawan Samagri with Pooja Kit", "pooja-3", "1 kit", "₹149", "₹299", "50% OFF", chip="200 g", similar=True),
        P("Classic Kaju Katli Indian Mithai Gift Box", "sweets-1", "200 g", "₹249", "₹399", "₹150 OFF", chip="Cashew", similar=True),
        P("Traditional Brass Akhand Diya with Glass Cover", "brassdiya-3", "1 pc", "₹299", "₹599", "50% OFF", chip="Brass", similar=True),
    ],
}


def product_card(p: dict) -> str:
    stars = ""
    if p["rating"]:
        full = "".join(icon("star") for _ in range(int(p["rating"])))
        empty = "".join(icon("star") for _ in range(5 - int(p["rating"])))
        stars = (
            f'<div class="product__rating"><span class="product__stars">{full}'
            f'<span style="color:#DCDCDC">{empty}</span></span>'
            f'{e(p["reviews"])}</div>'
        )
    meta = ""
    if p["time"] or p["stock"]:
        meta = (
            '<div class="product__meta">'
            f'<span class="clock">{icon("clock")}{e(p["time"])}</span>'
            + (f'<span class="product__stock">{e(p["stock"])}</span>' if p["stock"] else "")
            + "</div>"
        )
    qty = e(p["qty"])
    if p["variants"]:
        qty += f'<span style="display:block;font-size:9px;color:#0C831F;font-weight:700">{e(p["variants"])}</span>'
    return f"""<article class="product" data-name="{e(p['name'].lower())}" data-price="{e(p['price'])}">
  <figure class="product__media">
    <img src="{img(p['image'])}" alt="{e(p['name'])}" loading="eager" decoding="async" width="400" height="400">
    <button class="product__wish" type="button" aria-label="Add {e(p['name'])} to wishlist" aria-pressed="false">{icon('heart')}</button>
    <span class="product__dots" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
    {f'<span class="product__ad">Ad</span>' if p['ad'] else ''}
    {f'<span class="product__badge">{e(p["badge"])}</span>' if p['badge'] else ''}
    <span class="product__qty">{qty}</span>
    <button class="product__add" type="button" aria-label="Add {e(p['name'])} to cart">ADD</button>
    <span class="product__stepper" role="group" aria-label="Quantity for {e(p['name'])}">
      <button type="button" data-step="-1" aria-label="Decrease quantity">−</button>
      <span class="product__count">1</span>
      <button type="button" data-step="1" aria-label="Increase quantity">+</button>
    </span>
  </figure>
  <div class="product__body">
    <div class="product__price-row">
      <span class="product__price{' product__price--hl' if p['hl'] else ''}">{e(p['price'])}</span>
      <s class="product__mrp">{e(p['mrp'])}</s>
    </div>
    {f'<div class="product__offer">{e(p["offer"])}</div>' if p['offer'] else ''}
    <h3 class="product__name">{e(p['name'])}</h3>
    {f'<span class="product__chip">{e(p["chip"])}</span>' if p['chip'] else ''}
    {stars}{meta}
    {f'<button class="product__similar" type="button">See more like this {icon("arrow-right")}</button>' if p['similar'] else ''}
  </div>
</article>"""


def rail(items: list, extra_class: str = "") -> str:
    return (
        f'<div class="rail {extra_class}" role="region" aria-label="Product carousel" tabindex="0">'
        f'<button class="rail-nav rail-nav--prev" type="button" aria-label="Scroll products left">{icon("arrow-left")}</button>'
        + "".join(product_card(p) for p in items)
        + f'<button class="rail-nav rail-nav--next" type="button" aria-label="Scroll products right">{icon("arrow-right")}</button>'
        + "</div>"
    )


def section(title: str, subtitle: str, items: list, *, cream=False, id_="", reveal=True) -> str:
    label_attr = f' aria-labelledby="h-{id_}"' if id_ else ""
    return f"""<section class="section{' section--cream' if cream else ''} {'reveal' if reveal else ''}" {f'id="{id_}"' if id_ else ''}{label_attr}>
  <div class="section__head">
    <h2 class="section__title" {f'id="h-{id_}"' if id_ else ''}>{e(title)}</h2>
    {f'<p class="section__sub">{e(subtitle)}</p>' if subtitle else ''}
  </div>
</section>
<div class="section section--plain {'reveal' if reveal else ''}" style="padding-top:0;background:{'var(--cream)' if cream else '#fff'}">
  {rail(items)}
</div>"""


def display_head(eyebrow: str, title: str, note: str = "", *, light=False) -> str:
    return f"""<header class="display-head">
  <span class="display-head__eyebrow">{e(eyebrow)}</span>
  <h2 class="display-head__title">{icon('ornament', 'orn')}<span>{title}</span>{icon('ornament', 'orn')}</h2>
  {f'<p class="display-head__note">{e(note)}</p>' if note else ''}
</header>"""


def arch_card(image: str, title: str, sub: str, href: str = "diwali.html") -> str:
    # Titles are trusted static copy and may contain pre-escaped entities.
    return f"""<a class="arch-card" href="{href}">
  <img src="{img(image)}" alt="{title}" loading="eager" decoding="async">
  <span class="arch-card__foot">
    <span class="arch-card__title">{title}</span>
    <span class="arch-card__sub">{sub}</span>
    <span class="arch-card__arrow">{icon('arrow-right')}</span>
  </span>
</a>"""


def sq_tile(image: str, label: str, href: str = "diwali.html") -> str:
    return f"""<a class="sq-tile" href="{href}">
  <img class="sq-tile__img" src="{img(image)}" alt="{label}" loading="eager" decoding="async">
  <span class="sq-tile__label">{label}</span>
</a>"""


def see_all() -> str:
    return """<div class="see-all-wrap reveal">
  <a class="see-all" href="diwali.html">
    <span class="see-all__stack">
      <img src="assets/img/hamper-1.jpg" alt="" loading="eager"><img src="assets/img/diya-3.jpg" alt="" loading="eager"><img src="assets/img/urli-2.jpg" alt="" loading="eager">
    </span>
    <span>See all products</span>
    <svg aria-hidden="true"><use href="#i-arrow-right"></use></svg>
  </a>
</div>"""


# --------------------------------------------------------------------------
# Headers / navigation / footer
# --------------------------------------------------------------------------
TABS = [
    ("all", "All", "index.html"),
    ("diwali", "Diwali", "diwali.html"),
    ("party", "Party", "#"),
    ("electronics", "Electronics", "#"),
    ("beauty", "Beauty", "#"),
    ("gift", "Gifting", "#"),
]


def tabs_html(active: str) -> str:
    out = []
    for key, label, href in TABS:
        ico = {"all": "all", "diwali": "diya", "party": "party",
               "electronics": "headphones", "beauty": "beauty", "gift": "gift"}[key]
        cls = "tab is-active" if key == active else "tab"
        out.append(
            f'<a class="{cls}" href="{href}" data-tab="{key}"'
            + (' aria-current="page"' if key == active else "")
            + f'>{icon(ico)}<span>{label}</span></a>'
        )
    return '<nav class="tabs" aria-label="Shop categories">' + "".join(out) + "</nav>"


def search_row(placeholder: str) -> str:
    return f"""<form class="search-row" role="search" onsubmit="return false">
  <label class="search">
    <span class="sr-only">Search products</span>
    {icon('search')}
    <input type="search" name="q" placeholder="{e(placeholder)}" autocomplete="off" aria-label="Search products">
  </label>
  <button class="voice" type="button" aria-label="Search by voice" aria-pressed="false">{icon('voice')}</button>
</form>"""


def home_header() -> str:
    return f"""<header class="hero-head">
  {strand('top')}
  <div class="lattice lattice--strong" aria-hidden="true"></div>
  <div class="shell hero-head__inner">
    <div class="delivery">
      <div>
        <p class="delivery__eyebrow">Blinkit in</p>
        <p class="delivery__time">16 <span>minutes</span></p>
      </div>
      <div class="delivery__actions">
        <span class="wallet">{icon('wallet')} ₹0</span>
        <button class="icon-btn" type="button" aria-label="Your account">{icon('user')}</button>
      </div>
    </div>
    <p class="location"><strong>HOME</strong><span class="location__sep">-</span>hdsyy uure, Hisar Railway {icon('chevron-down')}</p>
    {search_row('Search "house party"')}
    {tabs_html('diwali')}
  </div>
  {strand('bottom')}
</header>"""


def store_header() -> str:
    return f"""<header class="store-head" id="storeHead">
  <div class="shell">
    <div class="top-line">
      <a class="brand-mark" href="index.html">{icon('diya')} blinkit</a>
      <span class="store-head__time">{icon('bolt')} Delivery in 16 minutes</span>
    </div>
    {search_row('Search for atta, dal, coke and more')}
    {tabs_html('diwali')}
  </div>
</header>"""


def bottom_nav(active: str) -> str:
    items = [
        ("home", "Home", "index.html"),
        ("orders", "Order Again", "#"),
        ("grid", "Categories", "diwali.html"),
        ("print", "Print", "#"),
    ]
    out = []
    for key, label, href in items:
        cls = "nav-item is-active" if key == active else "nav-item"
        out.append(f'<a class="{cls}" href="{href}">{icon(key)}<span>{label}</span></a>')
    out.append('<a class="nav-zomato" href="#footer">zomato</a>')
    return '<nav class="bottom-nav" aria-label="Primary navigation">' + "".join(out) + "</nav>"


def footer() -> str:
    return """<footer class="footer" id="footer">
  <div class="shell footer__grid">
    <div>
      <p class="footer__brand">Diwali Store</p>
      <p class="footer__tagline">Everything for a brighter festive season — diyas, decor, gifts, sweets and lights, delivered in minutes.</p>
    </div>
    <div><h3>Shop</h3><ul><li><a href="diwali.html">Diwali collection</a></li><li><a href="diwali.html">Gift hampers</a></li><li><a href="diwali.html">Home decor</a></li><li><a href="diwali.html">Pooja essentials</a></li></ul></div>
    <div><h3>Explore</h3><ul><li><a href="index.html">Home screen</a></li><li><a href="diwali.html">Festive calendar</a></li><li><a href="diwali.html">Shop by brands</a></li><li><a href="diwali.html">Festive lights</a></li></ul></div>
    <div><h3>Help</h3><ul><li><a href="#footer">Contact us</a></li><li><a href="#footer">Delivery areas</a></li><li><a href="#footer">Returns</a></li><li><a href="#footer">Privacy</a></li></ul></div>
  </div>
  <div class="shell footer__bottom"><span>© 2026 Diwali Store. A design recreation.</span><span>Made with care for the festival of lights ✦</span></div>
</footer>"""


def floating_ui() -> str:
    return """<button class="back-top" id="backTop" type="button" aria-label="Back to top">
  <svg aria-hidden="true"><use href="#i-arrow-up"></use></svg> Back to top
</button>
<div class="cart-bar" id="cartBar" role="status" aria-live="polite">
  <span class="cart-bar__count" id="cartCount">1 item</span>
  <span class="cart-bar__label">Festive cart</span>
  <span class="cart-bar__price" id="cartPrice">₹0</span>
  <svg aria-hidden="true"><use href="#i-arrow-right"></use></svg>
</div>
<div class="toast" id="toast" role="status" aria-live="polite"></div>"""


def page(title: str, description: str, body: str, *, theme: str) -> str:
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="{theme}">
<meta name="description" content="{e(description)}">
<title>{e(title)}</title>
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='8' fill='%23790131'/%3E%3Cpath d='M16 6c3 2.5 4 4.5 4 6.2 0 2-1.8 3.4-4 3.4s-4-1.4-4-3.4C12 10.5 13 8.5 16 6Z' fill='%23FFD27A'/%3E%3Cpath d='M5 18h22l-2.4 6H7.4Z' fill='%23FFD27A'/%3E%3C/svg%3E">
<link rel="preload" href="assets/fonts/dm-sans-latin-700-normal.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="assets/fonts/dm-serif-display-latin-400-normal.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="assets/css/styles.css">
<script defer src="assets/js/app.js"></script>
</head>
<body>
{SPRITE}
<a class="skip-link" href="#main">Skip to content</a>
<div class="page">
{body}
</div>
{floating_ui()}
</body>
</html>"""


# --------------------------------------------------------------------------
# Section builders
# --------------------------------------------------------------------------
def home_hero_body() -> str:
    tiles = [
        ("diya-3", "Lights, Diya &amp; Decor"),
        ("decor-3", "Home Makeover"),
        ("hamper-1", "Sweets &amp; Hampers"),
        ("hamper-2", "Diwali Gift Shop"),
        ("appliance-1", "Appliances &amp; Gadgets"),
        ("ethnic-2", "Festive Ready"),
    ]
    tile_html = "".join(
        f'<a class="tile" href="diwali.html"><span class="tile__glow"></span>'
        f'<span class="tile__label">{label}</span>'
        f'<img class="tile__img" src="{img(im)}" alt="{label}" loading="eager" decoding="async">'
        f"</a>"
        for im, label in tiles
    )
    return f"""<section class="hero-body" aria-labelledby="heroTitle">
  <div class="hero-body__pattern" aria-hidden="true"></div>
  <div class="shell">
    <header class="hero-title">
      <span class="hero-title__eyebrow">Get ready for</span>
      <h1 class="hero-title__word" id="heroTitle">{icon('ornament', 'orn')} Diwali {icon('ornament', 'orn')}</h1>
      <p class="hero-title__date">8<sup>TH</sup> NOVEMBER, SUNDAY</p>
    </header>
    <div class="tile-grid">{tile_html}</div>
  </div>
  <div class="shell"><div class="divider divider--light" style="margin-top:20px"></div></div>
</section>"""


def banner(eyebrow: str, title: str, cards: list, *, deep=False, bow=False, lotus=False,
           side="", extra_class="") -> str:
    sides = ""
    if bow:
        sides += """<svg class="banner__bow" viewBox="0 0 200 90" aria-hidden="true">
      <defs><linearGradient id="bowG" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#D87AA4"/><stop offset="1" stop-color="#9E2A63"/></linearGradient></defs>
      <path d="M100 44C72 12 28 8 16 34 4 60 48 72 100 44Z" fill="url(#bowG)"/>
      <path d="M100 44C128 12 172 8 184 34c12 26-32 38-84 10Z" fill="url(#bowG)"/>
      <path d="M84 42 60 86h80l-24-44Z" fill="#B84C7F"/>
      <ellipse cx="100" cy="45" rx="15" ry="13" fill="#E7A8C4"/>
      <circle cx="100" cy="45" r="5" fill="#FFF0DA"/>
    </svg>"""
    if lotus:
        sides += f'<span class="banner__side banner__side--left">{icon("lotus", "lotus")}</span>'
        sides += f'<span class="banner__side banner__side--right">{icon("lotus", "lotus")}</span>'
    if side == "gift":
        sides += '<img class="banner__side banner__side--left" src="assets/img/hamper-2.jpg" alt="" loading="eager">'
        sides += '<img class="banner__side banner__side--right" src="assets/img/hamper-4.jpg" alt="" loading="eager">'
    card_html = "".join(arch_card(*c) for c in cards)
    return f"""<section class="banner{' banner--deep' if deep else ' banner--cream-lite'} {extra_class} reveal">
  <div class="banner__frame" aria-hidden="true"></div>
  <div class="banner__crown" aria-hidden="true"></div>
  {sides}
  {display_head(eyebrow, title)}
  <div class="arch-rail">{card_html}</div>
</section>"""


def thoughtful_gifts() -> str:
    chips = [
        ("hamper-1", "Artisanal<br>gift boxes", True),
        ("candle-1", "Aroma &amp;<br>Diffusers", False),
        ("appliance-1", "Appliances", False),
        ("chocolate-4", "Gift<br>&amp; Kits", False),
        ("appliance-3", "Audio &amp;<br>Accessories", False),
    ]
    chip_html = "".join(
        f'<button class="chip-tile{" is-active" if active else ""}" type="button">'
        f'<span class="chip-tile__circle"><img src="{img(im)}" alt="" loading="eager"></span>'
        f"<span>{label}</span></button>"
        for im, label, active in chips
    )
    bow = """<svg class="banner__bow" viewBox="0 0 200 90" aria-hidden="true">
      <defs><linearGradient id="bowG" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#DC86B0"/><stop offset="1" stop-color="#9C2A62"/></linearGradient></defs>
      <path d="M100 44C72 12 28 8 16 34 4 60 48 72 100 44Z" fill="url(#bowG)"/>
      <path d="M100 44C128 12 172 8 184 34c12 26-32 38-84 10Z" fill="url(#bowG)"/>
      <path d="M84 42 60 86h80l-24-44Z" fill="#B84C7F"/>
      <ellipse cx="100" cy="45" rx="15" ry="13" fill="#E7A8C4"/>
      <circle cx="100" cy="45" r="5" fill="#FFF0DA"/>
    </svg>"""
    return f"""<section class="banner banner--cream-lite gifts reveal" aria-labelledby="giftsTitle">
  <div class="banner__frame" aria-hidden="true"></div>
  <div class="banner__crown" aria-hidden="true"></div>
  {bow}
  <header class="gifts-head">
    <h2 class="gifts-head__title" id="giftsTitle">Thoughtful Gifts for All</h2>
  </header>
  <div class="divider divider--on-wine" aria-hidden="true"></div>
  <div class="chip-rail" role="group" aria-label="Gift categories">{chip_html}</div>
  <div class="divider divider--tight" aria-hidden="true"></div>
  <div class="gifts-rail">{rail(PRODUCTS['gifts'])}</div>
</section>"""


def diyas_candles() -> str:
    items = [
        ("rangoli-2", "Designer Diya"), ("brassdiya-3", "Akhand Diya"),
        ("candle-1", "Tealight Candles"), ("candle-5", "Floating Candles"),
        ("brassdiya-2", "Brass Diya"), ("candle-3", "Wax Diya"),
        ("candle-4", "Pillar Candles"), ("candle-2", "Jar Candles"),
    ]
    grid = "".join(
        f'<a class="diamond" href="diwali.html"><span class="diamond__shape">'
        f'{icon("spark", "diamond__spark")}'
        f'<img class="diamond__img" src="{img(im)}" alt="{e(label)}" loading="eager"></span>'
        f'<span class="diamond__label">{e(label)}</span></a>'
        for im, label in items
    )
    return f"""<section class="banner banner--cream-lite reveal" aria-labelledby="dcTitle">
  <div class="banner__frame" aria-hidden="true"></div>
  <div class="banner__crown" aria-hidden="true"></div>
  <header class="display-head">
    <span class="display-head__eyebrow" id="dcTitle">Light up</span>
    <h2 class="display-head__title">{icon('ornament', 'orn')} Diyas &amp; Candles {icon('ornament', 'orn')}</h2>
  </header>
  <div class="diamond-grid">{grid}</div>
  <div class="divider divider--tight"></div>
</section>"""


def festive_calendar() -> str:
    cards = [
        ("urli-3", "29", "OCT", "Karwa Chauth"),
        ("pooja-1", "1", "NOV", "Ahoi Ashtami"),
        ("sweets-3", "N", "OV", "Dhanteras"),
    ]
    out = "".join(
        f'<article class="cal-card"><span class="cal-card__date">{d}<small>{m}</small></span>'
        f'<div class="cal-card__media"><img src="{img(im)}" alt="{e(label)}" loading="eager"></div>'
        f'<div class="cal-card__label">{e(label)}</div></article>'
        for im, d, m, label in cards
    )
    return f"""<section class="banner banner--cream-lite reveal" aria-labelledby="calTitle">
  <div class="banner__frame" aria-hidden="true"></div>
  <div class="divider divider--tight"></div>
  <header class="display-head" style="position:relative">
    {f'<span class="banner__side banner__side--left" style="top:6px">{icon("lotus", "lotus")}</span>'}
    {f'<span class="banner__side banner__side--right" style="top:6px">{icon("lotus", "lotus")}</span>'}
    <h2 class="display-head__title" id="calTitle">{icon('ornament', 'orn')} Festive Calendar {icon('ornament', 'orn')}</h2>
  </header>
  <div class="calendar-cards">{out}</div>
  <div class="divider divider--tight"></div>
</section>"""


def brands() -> str:
    items = [
        ("glasses-1", "Nestasia", "nestasia"),
        ("decor-5", "Chumbak", "CHUMBAK"),
        ("chocolate-1", "Ferrero", "Ferrero"),
    ]
    out = "".join(
        f'<a class="brand" href="diwali.html"><div class="brand__img"><img src="{img(im)}" alt="{e(label)}" loading="eager"></div>'
        f'<span class="brand__logo">{logo}</span><div class="brand__foot">{e(label)}</div></a>'
        for im, label, logo in items
    )
    return f"""<section class="banner banner--cream-lite reveal" aria-labelledby="brTitle">
  <div class="banner__frame" aria-hidden="true"></div>
  <div class="divider divider--tight"></div>
  <header class="display-head">
    <h2 class="display-head__title" id="brTitle">{icon('ornament', 'orn')} Shop by Brands {icon('ornament', 'orn')}</h2>
  </header>
  <div class="brands">{out}</div>
  <div class="divider divider--tight"></div>
</section>"""


def tile_banner(eyebrow: str, title: str, tiles: list, *, deep=True, note="") -> str:
    n = len(tiles)
    grid = "".join(sq_tile(*t) for t in tiles)
    slug = "".join(c.lower() for c in title if c.isalnum())
    return f"""<section class="banner{' banner--deep' if deep else ' banner--cream-lite'} reveal" aria-labelledby="tb-{slug}">
  <div class="banner__frame" aria-hidden="true"></div>
  <div class="banner__crown" aria-hidden="true"></div>
  <header class="display-head" id="tb-{slug}">
    <span class="display-head__eyebrow">{e(eyebrow)}</span>
    <h2 class="display-head__title">{title}</h2>
  </header>
  {f'<p class="display-head__note" style="text-align:center;padding-bottom:10px">{e(note)}</p>' if note else ''}
  <div class="tile-row{' tile-row--3' if n == 3 else ''}">{grid}</div>
</section>"""


def promo_card() -> str:
    return """<section class="promo-wrap reveal" aria-labelledby="promoTitle">
  <a class="promo-card" href="diwali.html">
    <span class="promo-card__glow" aria-hidden="true"></span>
    <span class="promo-card__text">
      <span class="promo-card__eyebrow">The full festive edit</span>
      <strong id="promoTitle">Explore the entire Diwali store</strong>
      <span class="promo-card__sub">Diyas, decor, gifts, lights &amp; everything in between</span>
    </span>
    <span class="promo-card__cta" aria-hidden="true"><svg><use href="#i-arrow-right"></use></svg></span>
    <img class="promo-card__img" src="assets/img/diya-4.jpg" alt="" loading="eager">
  </a>
</section>"""


# --------------------------------------------------------------------------
# Pages
# --------------------------------------------------------------------------
def build_home() -> str:
    body = f"""<a id="main"></a>
{home_header()}
<main>
  {home_hero_body()}
  {section("Bring home your festive vibes", "Set your space aglow with diyas", PRODUCTS['festive_vibes'], id_='vibes')}
  {see_all()}
  {banner('Time for your', 'Festive Shopping', [
      ('decor-2', 'Festive Home', 'Set your space aglow'),
      ('hamper-3', 'Hosting Ready', 'Serve up a festive feast'),
      ('sweets-2', 'Sweet Shop', 'Savour tempting treats'),
      ('hamper-5', 'Gifting Corner', 'Gifts for your loved ones'),
  ])}
  {section("Make every entrance look special", "Get toran, urli and more", PRODUCTS['entrance'], id_='entrance')}
  {diyas_candles()}
  {section("Get your home Diwali-ready with lights", "Brighten every corner", PRODUCTS['lights'], id_='lights')}
  {festive_calendar()}
  {brands()}
  {promo_card()}
</main>
{footer()}
{bottom_nav('home')}"""
    return page("Home · Diwali Store", "Festive home screen — shop Diwali decor, diyas, gifts and lights delivered in minutes.", body, theme="#790131")


def build_diwali() -> str:
    body = f"""<a id="main"></a>
{store_header()}
<main>
  {section("Bring home your festive vibes", "Set your space aglow with diyas", PRODUCTS['festive_vibes'], cream=True, id_='vibes')}
  {banner('Time for your', 'Festive Shopping', [
      ('decor-2', 'Festive Home', 'Set your space aglow'),
      ('hamper-3', 'Hosting Ready', 'Serve up a festive feast'),
      ('sweets-2', 'Sweet Shop', 'Savour tempting treats'),
      ('hamper-5', 'Gifting Corner', 'Gifts for your loved ones'),
  ])}
  {section("Make every entrance look special", "Get toran, urli and more", PRODUCTS['entrance'], id_='entrance')}
  {see_all()}
  {thoughtful_gifts()}
  {banner('Find your ideal', 'Vibrant Decor', [
      ('decor-1', 'Table Styling', 'Get urli, flowers &amp; more'),
      ('rangoli-4', 'Floor Decor', 'Rangoli colours &amp; stickers'),
      ('decor-4', 'Festive Corners', 'Make every nook shine'),
      ('glasses-2', 'Dining Edit', 'Serve in style'),
  ], extra_class='banner--decor')}
  {section("Get your home Diwali-ready with lights", "Warm glows for every corner", PRODUCTS['lights'], id_='lights')}
  {diyas_candles()}
  {festive_calendar()}
  {section("Add warmth to your ambience", "Get candles, toran, urlis and more", PRODUCTS['warmth'], cream=True, id_='warmth')}
  {banner('Share joy with', 'Diwali Gifting', [
      ('hamper-1', 'Festive Gifts', 'Find the perfect surprise'),
      ('decor-5', 'Home &amp; Living', 'Gifts that feel like home'),
      ('appliance-2', 'Electronics', 'Smart little surprises'),
  ], deep=True, side='gift')}
  {brands()}
  {section("Let the celebrations shine through", "Get jharokhas, stickers, and more", PRODUCTS['celebrations'], id_='celebrations')}
  {tile_banner('Refresh your', 'Festive Home', [
      ('decor-5', 'Home Makeover'), ('decor-2', 'Artful Decor'),
      ('rose-3', 'Flowers &amp; Vases'), ('glasses-1', 'Dining Essentials'),
  ])}
  {section("Refurbish your every corner", "Little touches, big difference", PRODUCTS['corner'], id_='corner')}
  {tile_banner('All for your', 'Diwali Outfit', [
      ('ethnic-1', 'Kurta &amp; Saree'), ('ethnic-2', 'Jewellery'),
      ('beauty-1', 'Makeup Essentials'), ('beauty-2', 'Haircare &amp; Skincare'),
  ], deep=True)}
  {tile_banner('Go-to stop for', 'Pooja Essentials', [
      ('pooja-1', 'Idols &amp; Photos'), ('brassdiya-1', 'Hawan Needs'),
      ('sweets-1', 'Indian Sweets'), ('pooja-4', 'Mandir Decor'),
  ], deep=False)}
  {section("Make every ritual more meaningful", "Everything for your puja thali", PRODUCTS['rituals'], cream=True, id_='rituals')}
  {promo_card()}
</main>
{footer()}
{bottom_nav('grid')}"""
    return page("Diwali Store · Festival Edit", "The complete Diwali store — diyas, candles, gifts, decor, lights and pooja essentials.", body, theme="#FBF9ED")


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    (ROOT / "index.html").write_text(build_home(), encoding="utf-8")
    (ROOT / "diwali.html").write_text(build_diwali(), encoding="utf-8")
    print("wrote", ROOT / "index.html", (ROOT / "index.html").stat().st_size, "bytes")
    print("wrote", ROOT / "diwali.html", (ROOT / "diwali.html").stat().st_size, "bytes")


if __name__ == "__main__":
    main()
