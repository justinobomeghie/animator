var L=t=>{throw TypeError(t)};var _=(t,n,i)=>n.has(t)||L("Cannot "+i);var l=(t,n,i)=>(_(t,n,"read from private field"),i?i.call(t):n.get(t)),c=(t,n,i)=>n.has(t)?L("Cannot add the same private member more than once"):n instanceof WeakSet?n.add(t):n.set(t,i),d=(t,n,i,a)=>(_(t,n,"write to private field"),a?a.call(t,i):n.set(t,i),i);(function(){const n=document.createElement("link").relList;if(n&&n.supports&&n.supports("modulepreload"))return;for(const P of document.querySelectorAll('link[rel="modulepreload"]'))a(P);new MutationObserver(P=>{for(const s of P)if(s.type==="childList")for(const r of s.addedNodes)r.tagName==="LINK"&&r.rel==="modulepreload"&&a(r)}).observe(document,{childList:!0,subtree:!0});function i(P){const s={};return P.integrity&&(s.integrity=P.integrity),P.referrerPolicy&&(s.referrerPolicy=P.referrerPolicy),P.crossOrigin==="use-credentials"?s.credentials="include":P.crossOrigin==="anonymous"?s.credentials="omit":s.credentials="same-origin",s}function a(P){if(P.ep)return;P.ep=!0;const s=i(P);fetch(P.href,s)}})();class u{static fromArray(n,i){return w(n,i)}[Symbol.iterator](){return new y(this)}toArray(){return[...this]}atLeastLength(n){let i=this;for(;n-- >0&&i;)i=i.tail;return i!==void 0}hasLength(n){let i=this;for(;n-- >0&&i;)i=i.tail;return n===-1&&i instanceof p}countLength(){let n=this,i=0;for(;n;)n=n.tail,i++;return i-1}}function e(t,n){return new f(t,n)}function w(t,n){let i=n||o;for(let a=t.length-1;a>=0;--a)i=new f(t[a],i);return i}var h;class y{constructor(n){c(this,h);d(this,h,n)}next(){if(l(this,h)instanceof p)return{done:!0};{let{head:n,tail:i}=l(this,h);return d(this,h,i),{value:n,done:!1}}}}h=new WeakMap;class p extends u{}const o=new p;class f extends u{constructor(n,i){super(),this.head=n,this.tail=i}}e("y",o),e(["Line",e("start",e("end",o))],e(["Path",e("shape",e("start",e("end",e("thickness",o))))],o));e(["square_spiral",`fn draw(shape_slider: Int) -> List(Path) {
  let turns = 20 + shape_slider / 4
  spiral(Point(0, 0), Point(1, 0), 0, turns)
}

fn spiral(p: Point, d: Point, i: Int, n: Int) -> List(Path) {
  case i == n {
    True -> []
    False -> {
      let len = { i / 2 + 1 } * 12
      let q = Point(p.x + d.x * len, p.y + d.y * len)
      [
        Path(Line(p, q), i * 2, i * 2 + 5, 3),
        ..spiral(q, Point(0 - d.y, d.x), i + 1, n)
      ]
    }
  }
}
`],o);e(["fan",`fn draw(shape_slider: Int) -> List(Path) {
  fan(30, Point(-200, -200))
}

fn fan(n: Int, start: Point) -> List(Path) {
  case n > 0 {
    True -> [Path(Line(start, Point(n * 10, 200)), 0, 30, 3), ..fan(n - 1, start)]
    False -> []
  }
}
`],e(["square_spiral",`fn draw(shape_slider: Int) -> List(Path) {
  let turns = 20 + shape_slider / 4
  spiral(Point(0, 0), Point(1, 0), 0, turns, [])
}

fn spiral(p: Point, d: Point, i: Int, n: Int, acc: List(Path)) -> List(Path) {
  case i == n {
    True -> acc
    False -> {
      let len = { i / 2 + 1 } * 24
      let q = Point(p.x + d.x * len, p.y + d.y * len)
      spiral(q, Point(0 - d.y, d.x), i + 1, n, [Path(Line(p, q), i * 3, i * 3 + 3, 3), ..acc])
    }
  }
}
`],e(["string_art",`fn draw(shape_slider: Int) -> List(Path) {
  let n = 8 + shape_slider / 10
  list.flatten([
    quadrant(1, 1, n, 0),
    quadrant(-1, 1, n, n + 1),
    quadrant(-1, -1, n, { n + 1 } * 2),
    quadrant(1, -1, n, { n + 1 } * 3),
  ])
}

fn quadrant(sx: Int, sy: Int, n: Int, base: Int) -> List(Path) {
  strings(0, sx, sy, n, base)
}

fn strings(i: Int, sx: Int, sy: Int, n: Int, base: Int) -> List(Path) {
  case i > n {
    True -> []
    False -> {
      let a = Point(sx * 420 * i / n, 0)
      let b = Point(0, sy * 420 * { n - i } / n)
      let t = { base + i } * 2
      [Path(Line(a, b), t, t + 8, 2), ..strings(i + 1, sx, sy, n, base)]
    }
  }
}
`],e(["tree",`fn draw(shape_slider: Int) -> List(Path) {
  let depth = 4 + shape_slider / 20
  branch(Point(0, 420), Point(0, -220), 0, depth)
}

fn branch(p: Point, d: Point, level: Int, depth: Int) -> List(Path) {
  case level == depth {
    True -> []
    False -> {
      let q = Point(p.x + d.x, p.y + d.y)
      let left = Point({ d.x - d.y } / 2, { d.y + d.x } / 2)
      let right = Point({ d.x + d.y } / 2, { d.y - d.x } / 2)
      [
        Path(Line(p, q), level * 4, level * 4 + 4, depth - level),
        ..list.append(
          branch(q, left, level + 1, depth),
          branch(q, right, level + 1, depth),
        )
      ]
    }
  }
}
`],o))));
