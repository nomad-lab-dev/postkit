# Screen: Posts List (v0.1)

**Path:** `TabBar / Posts`
**View:** `PostsListView`
**ViewModel:** `PostsListViewModel`
**Story:** PB-020

---

## Purpose

Overview of all posts. Visual slots show completion at a glance.

## Specs

- Title: "Your Posts"
- Filter tabs: All / Draft / Ready / Published
- **Post cards** in vertical list:
  - **4 visual slots** (filled = thumbnail, empty = dotted outline)
  - Post name + description (1 line)
  - Status badge (Draft = gray, Ready = blue, Published = green)
  - Asset count + date
- **"+" button:** Create new post
- **Tap post:** → Post Editor detail
- **Long press:** Context menu (Duplicate, Delete, Export to Album)
- **No swipe status change** (removed in v0.1)

## Edge Cases

- **No posts:** Empty state CTA
- **Post with broken assets:** Warning badge
- **Cancel a post:** Assets return to "non-utilise" state

## Acceptance Criteria

- [ ] 4 visual slots per card (filled/empty)
- [ ] Tap → detail
- [ ] Long press → context menu
- [ ] Cancel returns assets to non-utilise
- [ ] Filter tabs work
