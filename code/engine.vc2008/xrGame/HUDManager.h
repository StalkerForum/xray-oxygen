#pragma once

#include "../xrEngine/CustomHUD.h"
#include "HitMarker.h"

class CHUDTarget;
class CUIGame;

class CHUDManager : public CCustomHUD
{
	friend class CUI;

private:
	CHitMarker HitMarker;
	CHUDTarget* m_pHUDTarget;
	bool b_online;

public:
	CHUDManager();
	virtual ~CHUDManager();
	virtual void OnEvent(EVENT E, u64 P1, u64 P2);

	virtual void Render_First();
	virtual void Render_Last();
	virtual void Render_Actor_Shadow();
	virtual void OnFrame();

	virtual void RenderUI();

	CUIGame* GetGameUI() { return (CUIGame*)pUIHud; }

	void HitMarked(int idx, float power, const Fvector& dir);
	bool AddGrenade_ForMark(CGrenade* grn);
	void Update_GrenadeView(Fvector& pos_actor);
	void net_Relcase(CObject* obj);

	//текущий предмет на который смотрит HUD
	collide::rq_result& GetCurrentRayQuery();

	//устанвка внешнего вида прицела в зависимости от текущей дисперсии
	void SetCrosshairDisp(float dispf, float disps = 0.f);
#ifdef DEBUG
	void SetFirstBulletCrosshairDisp(float fbdispf);
#endif
	void ShowCrosshair(bool show);

	void SetHitmarkType(LPCSTR tex_name);
	void SetGrenadeMarkType(LPCSTR tex_name);

	virtual void OnScreenResolutionChanged();
	virtual	void Load();
	virtual void OnDisconnected();
	virtual void OnConnected();

	virtual	void RenderActiveItemUI();
	virtual	bool RenderActiveItemUIQuery();

	//Lain: added
	void SetRenderable(bool renderable) { psHUD_Flags.set(HUD_DRAW_RT2, renderable); }
};

inline CHUDManager& HUD() { return *((CHUDManager*)g_hud); }
